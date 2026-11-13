class_name BossArena
extends Node2D

## Arena de chefe genérica. Cuida de tudo que não é o chefe em si:
##   1. espera o Garibot cruzar `trigger_x` e trava a arena (paredes + câmera);
##   2. roda a cutscene de entrada e começa a luta (`boss.start_fight()`);
##   3. se o chefe emitir `interlude_requested`, pausa a luta, roda a cutscene do meio
##      e chama `boss.resume_fight()` no fim (ex.: o chefe acorda depois dos guardas);
##   4. quando o chefe emite `defeated`, roda a cutscene final e destrava a arena;
##   5. revela a recompensa (um `AreaCollectible` com `hidden_until_revealed`): ela sai
##      de onde o chefe avisar (`reward_dropped(posição)`) ou de onde o chefe está, e
##      quica até o chão ali embaixo.
##
## O chefe é qualquer nó com os sinais `defeated` e `progress_changed(atual, total)` e o
## método `start_fight()`; opcionais: `setup_arena(esquerda, direita, chao)` (limites
## globais da arena), o sinal `interlude_requested` com `resume_fight()`, o sinal
## `reward_dropped(posição)` e `die()`.
##
## Coordenadas (`left_x`, `right_x`, `trigger_x`) são relativas a este nó, que fica no
## chão, no meio da arena. Falas ficam no Dialogic: o passo "say" das cutscenes abre a
## timeline pela fase (via `start_dialogue`). Passos `{"type": "signal", ...}` extras:
##   "boss_call": "die"      chama esse método do chefe (ex.: a morte no meio da cutscene);
##   "reveal_reward": true   solta a recompensa ali (senão ela sai no fim da cutscene).
##
## A fase escuta `cutscene_started`/`cutscene_finished` (esconder/mostrar o HUD) e
## `hint_changed` (texto de instrução); `is_in_cutscene()` diz se a arena está no comando.

signal cutscene_started
signal cutscene_finished
signal fight_started
signal fight_finished
signal hint_changed(text: String)

enum Stage { WAITING, INTRO, FIGHT, INTERLUDE, OUTRO, REWARD, DONE }

@export var boss_path := NodePath("Boss")
@export var intro_cutscene_path := NodePath("IntroCutscene")
@export var interlude_cutscene_path := NodePath("InterludeCutscene")
@export var outro_cutscene_path := NodePath("OutroCutscene")
@export var health_bar_path := NodePath("BossBarLayer/BossHealthBar")
## Recompensa revelada no fim (fica escondida até lá). Caminho relativo a esta arena.
@export var reward_path: NodePath

@export_group("Área")
@export var left_x := -400.0
@export var right_x := 400.0
## O Garibot precisa passar deste X (e estar no chão) para a luta começar.
@export var trigger_x := -280.0
## A câmera desce até o chão + esta margem, para o céu (e o chefe) caberem na tela.
@export var camera_floor_margin := 56.0
## Distância das paredes invisíveis para fora dos limites da arena.
@export var wall_margin := 28.0
@export var wall_height := 900.0

@export_group("Textos")
@export_multiline var fight_hint := ""
## Instrução depois da cutscene do meio da luta (vazia = mantém `fight_hint`).
@export_multiline var interlude_hint := ""
@export_multiline var reward_hint := ""
## Pausa entre a derrota do chefe e a cutscene final (s).
@export var defeat_pause := 1.2
## Altura do pulinho da recompensa ao sair (px).
@export var reward_hop_height := 36.0
## Tempo da recompensa saindo até parar no chão (s).
@export var reward_drop_time := 1.1

var stage := Stage.WAITING

var _player: Player
var _walls: Array[CollisionShape2D] = []
var _saved_limits := {}
var _fight_start_ms := 0
var _reward_revealed := false

@onready var boss: Node2D = get_node(boss_path)
@onready var intro_cutscene: CutscenePlayer = get_node_or_null(intro_cutscene_path)
@onready var interlude_cutscene: CutscenePlayer = get_node_or_null(interlude_cutscene_path)
@onready var outro_cutscene: CutscenePlayer = get_node_or_null(outro_cutscene_path)
@onready var health_bar: BossHealthBar = get_node_or_null(health_bar_path)
@onready var reward: AreaCollectible = get_node_or_null(reward_path)


func _ready() -> void:
	_build_walls()
	# O chefe é "duck-typed": qualquer nó com estes sinais/métodos serve.
	boss.connect(&"defeated", _on_boss_defeated)
	boss.connect(&"progress_changed", _on_boss_progress)
	if boss.has_signal(&"interlude_requested"):
		boss.connect(&"interlude_requested", _on_boss_interlude)
	if boss.has_signal(&"reward_dropped"):
		boss.connect(&"reward_dropped", _reveal_reward_at)
	if boss.has_method(&"setup_arena"):
		boss.call(
			&"setup_arena",
			to_global(Vector2(left_x, 0)).x,
			to_global(Vector2(right_x, 0)).x,
			global_position.y
		)
	for cutscene: CutscenePlayer in [intro_cutscene, interlude_cutscene, outro_cutscene]:
		if cutscene:
			cutscene.step_reached.connect(_on_cutscene_step)
	if intro_cutscene:
		intro_cutscene.finished.connect(_start_fight)
	if interlude_cutscene:
		interlude_cutscene.finished.connect(_on_interlude_finished)
	if outro_cutscene:
		outro_cutscene.finished.connect(_on_outro_finished)
	if health_bar:
		health_bar.hide()
	if reward:
		reward.collected.connect(_on_reward_collected)


func _physics_process(_delta: float) -> void:
	if stage != Stage.WAITING:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		return
	var ready_to_start := (
		_player.global_position.x >= to_global(Vector2(trigger_x, 0)).x
		and _player.is_on_floor()
		and _player.has_control
		and not _player.in_cutscene
		and Dialogic.current_timeline == null
	)
	if ready_to_start:
		_begin()


## A arena está no comando (cutscene ou pausa dramática): a fase esconde o HUD.
func is_in_cutscene() -> bool:
	return (
		stage in [Stage.INTRO, Stage.INTERLUDE, Stage.OUTRO]
		or (intro_cutscene and intro_cutscene.is_running())
		or (interlude_cutscene and interlude_cutscene.is_running())
		or (outro_cutscene and outro_cutscene.is_running())
	)


func is_fighting() -> bool:
	return stage == Stage.FIGHT


## Usada pelo CutscenePlayer ("say"): repassa para a fase, que abre o diálogo nos balões.
func start_dialogue(timeline_path: String) -> void:
	var host := get_parent()
	if host and host.has_method("start_dialogue"):
		host.start_dialogue(timeline_path)
	else:
		Dialogic.start(timeline_path)


# --- Etapas --------------------------------------------------------------------------


func _begin() -> void:
	stage = Stage.INTRO
	_set_locked(true)
	cutscene_started.emit()
	Analytics.track("chefe_inicio", {"chefe": str(boss.name)})
	if intro_cutscene:
		intro_cutscene.run()
	else:
		_start_fight()


func _start_fight() -> void:
	stage = Stage.FIGHT
	_fight_start_ms = Time.get_ticks_msec()
	if health_bar:
		health_bar.show()
	boss.call(&"start_fight")
	cutscene_finished.emit()
	hint_changed.emit(fight_hint)
	fight_started.emit()


func _on_boss_interlude() -> void:
	if stage != Stage.FIGHT:
		return
	if interlude_cutscene == null:
		_on_interlude_finished.call_deferred()
		return
	stage = Stage.INTERLUDE
	hint_changed.emit("")
	cutscene_started.emit()
	interlude_cutscene.run()


func _on_interlude_finished() -> void:
	stage = Stage.FIGHT
	if boss.has_method(&"resume_fight"):
		boss.call(&"resume_fight")
	cutscene_finished.emit()
	hint_changed.emit(interlude_hint if not interlude_hint.is_empty() else fight_hint)


func _on_boss_progress(current: int, total: int) -> void:
	if health_bar:
		health_bar.set_progress(current, total)
	if stage == Stage.FIGHT and current > 0:
		Analytics.track("chefe_progresso", {"atual": current, "total": total})


func _on_boss_defeated() -> void:
	if stage != Stage.FIGHT:
		return
	stage = Stage.OUTRO
	hint_changed.emit("")
	cutscene_started.emit()
	Analytics.track(
		"chefe_derrotado",
		{"duracao_s": snappedf((Time.get_ticks_msec() - _fight_start_ms) / 1000.0, 0.1)}
	)
	await get_tree().create_timer(defeat_pause).timeout
	if outro_cutscene:
		outro_cutscene.run()
	else:
		_on_outro_finished()


func _on_outro_finished() -> void:
	if health_bar:
		health_bar.hide()
	if boss.has_method(&"die"):
		boss.call(&"die")
	_set_locked(false)
	_reveal_reward()
	stage = Stage.REWARD if reward else Stage.DONE
	cutscene_finished.emit()
	hint_changed.emit(reward_hint if reward else "")
	fight_finished.emit()


func _reveal_reward() -> void:
	_reveal_reward_at(boss.global_position)


## A recompensa sai de `origin`, dá um pulinho e quica até o chão embaixo dali (na
## altura em que ela está na cena).
func _reveal_reward_at(origin: Vector2) -> void:
	if reward == null or _reward_revealed:
		return
	_reward_revealed = true
	var left := to_global(Vector2(left_x, 0)).x
	var right := to_global(Vector2(right_x, 0)).x
	var target := Vector2(clampf(origin.x, left, right), reward.global_position.y)
	reward.reveal()
	if bool(Settings.get_setting("reduced_motion", false)) or reward_drop_time <= 0.0:
		reward.global_position = target
		return
	reward.global_position = origin
	var apex := Vector2(target.x, minf(origin.y, target.y) - reward_hop_height)
	var tween := create_tween()
	var hop := tween.tween_property(reward, "global_position", apex, reward_drop_time * 0.35)
	hop.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var land := tween.tween_property(reward, "global_position", target, reward_drop_time * 0.65)
	land.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _on_reward_collected(_item_name: String) -> void:
	stage = Stage.DONE
	hint_changed.emit("")


func _on_cutscene_step(step: Dictionary, _index: int) -> void:
	var method := StringName(str(step.get("boss_call", "")))
	if not method.is_empty() and boss.has_method(method):
		boss.call(method)
	if step.get("reveal_reward", false):
		_reveal_reward()


# --- Trava da arena ------------------------------------------------------------------


func _build_walls() -> void:
	for side_x: float in [left_x - wall_margin, right_x + wall_margin]:
		var body := StaticBody2D.new()
		body.collision_layer = 8  # "world": o Garibot colide, os inimigos também
		body.collision_mask = 0
		body.position = Vector2(side_x, -wall_height / 2.0)
		var shape := RectangleShape2D.new()
		shape.size = Vector2(16, wall_height)
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.disabled = true
		body.add_child(collision)
		add_child(body)
		_walls.append(collision)


func _set_locked(locked: bool) -> void:
	for wall in _walls:
		wall.set_deferred("disabled", not locked)
	var camera: Camera2D = null
	if _player:
		camera = _player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	if locked:
		_saved_limits = {
			"limit_left": camera.limit_left,
			"limit_right": camera.limit_right,
			"limit_bottom": camera.limit_bottom,
		}
		camera.limit_left = int(to_global(Vector2(left_x - wall_margin, 0)).x)
		camera.limit_right = int(to_global(Vector2(right_x + wall_margin, 0)).x)
		camera.limit_bottom = int(global_position.y + camera_floor_margin)
	else:
		for property: String in _saved_limits:
			camera.set(property, _saved_limits[property])
