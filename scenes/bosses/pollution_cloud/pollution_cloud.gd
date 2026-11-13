class_name PollutionCloud
extends Node2D

## Chefe da fase 1: a Nuvem de Poluição (placeholder com formas simples, sem sprite).
##
## Etapas da luta:
##   1. GUARDS: a nuvem fica "adormecida" no alto e chama dois rolling steal, que entram
##      rolando pela direita da arena (`call_guards`, normalmente na cutscene de entrada).
##   2. AWAKENING: os dois foram derrotados; ela acorda e emite `interlude_requested`
##      (a arena roda a cutscene com o diálogo) e espera `resume_fight()`.
##   3. NORMAL: alterna os ataques (`BossAttack` filhos de `Attacks`): chuva ácida que
##      cai de baixo dela e pilhas arremessadas. A cada `attacks_before_plant` ataques,
##      um canteiro de `HealingPlant` fica pronto; cada trepadeira limpa um pouco a nuvem.
##   4. STUNNED: com todas as plantas crescidas, emite `defeated` e fica parada.
##   5. DEAD: `die()` (chamado pela cutscene final) desfaz a nuvem; dela cai uma última
##      pilha, que estrebucha e morre em seguida, emitindo `reward_dropped` onde morreu
##      (a arena solta o REEE ali).
##
## Segue o contrato da `BossArena`. Os ataques usam `arena_left`, `arena_right`,
## `arena_floor_y`, `body_size`, `get_bottom()`, `set_anchor()`/`clear_anchor()` e
## `set_mood()`. Falas ficam no Dialogic (personagem `nuvem`, balão em `BubblePoint`).

signal defeated
signal progress_changed(current: int, total: int)
## Pede à arena uma pausa com cutscene; a luta só continua com `resume_fight()`.
signal interlude_requested
## A última pilha morreu em `at` (posição global): é dali que sai a recompensa.
signal reward_dropped(at: Vector2)

enum Phase { WAITING, GUARDS, AWAKENING, NORMAL, STUNNED, DEAD }

const MOOD_SLEEP := &"sleep"
const MOOD_IDLE := &"idle"
const MOOD_ATTACK := &"attack"
const MOOD_HURT := &"hurt"
const GUARD_SCENE := preload(
	"res://scenes/characters/enemies/rolling_steal/rolling_steal_enemy.tscn"
)
const BATTERY_SCENE := preload(
	"res://scenes/characters/enemies/acid_battery/acid_battery_enemy.tscn"
)
## Metade da altura do corpo de cada inimigo (a origem fica no meio).
const GUARD_HALF_HEIGHT := 27.0
const BATTERY_HALF_HEIGHT := 16.0

@export var attacks_path := NodePath("Attacks")
## Nó cujos filhos `HealingPlant` são os canteiros desta luta (em relação ao chefe).
@export var plants_path := NodePath("../Plants")

@export_group("Guardas")
## Patrulha de cada rolling steal: X das duas pontas, em relação ao centro da arena.
## Eles entram pela borda direita e rolam até a ponta mais perto dela.
@export var guard_patrols := PackedVector2Array([Vector2(330, 160), Vector2(60, -260)])
## Distância da borda direita da arena onde cada guarda aparece (px).
@export var guard_entry_inset := 16.0
## Intervalo entre a entrada de um guarda e a do próximo (s).
@export var guard_interval := 0.7

@export_group("Voo")
## Altura do centro da nuvem acima do chão da arena (px).
@export var hover_height := 130.0
## Quanto a nuvem passeia para cada lado do centro da arena (px).
@export var drift_amplitude := 200.0
## Duração de uma ida e volta do passeio (s).
@export var drift_period := 8.0
## 0 = só passeia; 1 = fica sempre em cima do Garibot.
@export_range(0.0, 1.0) var follow_player := 0.35
@export var move_speed := 70.0
## Velocidade indo até um ponto pedido por um ataque (`set_anchor`).
@export var anchor_speed := 170.0
@export var bob_height := 4.0

@export_group("Luta")
@export var first_attack_delay := 1.0
## Pausa entre um ataque e o próximo (s).
@export var attack_pause := 0.9
## Ataques entre uma planta crescida e a próxima ficar pronta.
@export var attacks_before_plant := 2
## Tempo atordoada depois de uma planta crescer (s); ela não ataca nesse tempo.
@export var hurt_time := 1.6

@export_group("Fim")
## Tempo da nuvem se desfazendo (s).
@export var vanish_time := 1.0
## Queda da última pilha até o chão (s).
@export var battery_fall_time := 0.5
## A última pilha estrebucha por este tempo antes de morrer (s).
@export var battery_struggle_time := 0.6
@export var battery_death_time := 0.3

@export_group("Visual")
## Largura e altura da nuvem; a chuva ácida usa a largura.
@export var body_size := Vector2(96, 48)
@export var dirty_color := Color("#5b5649")
## Cor quando todas as plantas cresceram (a nuvem vai clareando a cada uma).
@export var clean_color := Color("#c9cdc4")
@export var sleep_color := Color("#46433a")
@export var outline_color := Color("#18252a")
@export var eye_color := Color("#ffde59")
@export var attack_eye_color := Color("#ff6b4a")

## Limites globais da arena (ver `setup_arena`). Sem arena, ficam em volta da nuvem.
var arena_left := -400.0
var arena_right := 400.0
var arena_floor_y := 0.0
var phase := Phase.WAITING
var progress := 0

var _mood := MOOD_SLEEP
var _attacks: Array[BossAttack] = []
var _plants: Array[HealingPlant] = []
var _guards_called := false
var _guards_left := 0
var _current_attack: BossAttack
var _last_attack: BossAttack
var _attacks_since_plant := 0
var _fight_id := 0
var _hurt_until_ms := 0
var _time := 0.0
var _center_x := 0.0
var _anchor_x := NAN


func _ready() -> void:
	_center_x = global_position.x
	arena_left = global_position.x - 400.0
	arena_right = global_position.x + 400.0
	arena_floor_y = global_position.y + hover_height
	var attacks := get_node_or_null(attacks_path)
	if attacks:
		for child in attacks.get_children():
			var attack := child as BossAttack
			if attack:
				_attacks.append(attack)
	var plants := get_node_or_null(plants_path)
	if plants:
		for child in plants.get_children():
			var plant := child as HealingPlant
			if plant:
				_plants.append(plant)
				plant.target = self
				plant.grown.connect(_on_plant_grown)


func _process(delta: float) -> void:
	_time += delta
	if _mood == MOOD_HURT and not _is_hurt() and phase == Phase.NORMAL:
		_mood = MOOD_IDLE
	if phase == Phase.NORMAL:
		_drift(delta)
	_update_plant_anchors()
	queue_redraw()


func setup_arena(left: float, right: float, floor_y: float) -> void:
	arena_left = left
	arena_right = right
	arena_floor_y = floor_y
	_center_x = (left + right) / 2.0
	global_position = Vector2(_center_x, floor_y - hover_height)


## Começa pelos guardas (chama-os agora se a cutscene não chamou). Sem guardas, já
## começa acordada.
func start_fight() -> void:
	if phase != Phase.WAITING:
		return
	progress_changed.emit(progress, _plants.size())
	if guard_patrols.is_empty():
		_start_normal()
		return
	phase = Phase.GUARDS
	_mood = MOOD_SLEEP
	call_guards()


## Os rolling steal entram pela direita, um depois do outro. Pode ser chamado por um
## passo `{"type": "signal", "boss_call": "call_guards"}` da cutscene de entrada.
func call_guards() -> void:
	if _guards_called:
		return
	_guards_called = true
	# Já conta todos: um guarda pode cair antes de o próximo entrar.
	_guards_left = guard_patrols.size()
	for index in guard_patrols.size():
		if index > 0:
			await get_tree().create_timer(guard_interval).timeout
		_spawn_guard(guard_patrols[index])


## Chamado pela arena quando a cutscene do `interlude_requested` termina.
func resume_fight() -> void:
	if phase == Phase.AWAKENING:
		_start_normal()


func stop_fight() -> void:
	_fight_id += 1
	_anchor_x = NAN
	if _current_attack:
		_current_attack.stop()
	_current_attack = null
	for attack in _attacks:
		if attack.has_method(&"dismiss_summons"):
			attack.call(&"dismiss_summons")


## Expressão da nuvem. Adormecida, atordoada ou derrotada, ignora os ataques.
func set_mood(mood: StringName) -> void:
	if phase != Phase.NORMAL or _is_hurt():
		return
	_mood = mood
	queue_redraw()


## Ataques pedem para a nuvem ir até `x` e ficar ali (ex.: chover em cima do Garibot).
func set_anchor(x: float) -> void:
	var margin := body_size.x / 2.0
	_anchor_x = clampf(x, arena_left + margin, arena_right - margin)


func clear_anchor() -> void:
	_anchor_x = NAN


## Ponto global embaixo da nuvem, de onde caem a chuva e as pilhas.
func get_bottom() -> Vector2:
	return global_position + Vector2(0, body_size.y / 2.0 + _bob())


## Fim (depois de `defeated`): a nuvem se desfaz e solta a última pilha, que morre
## logo depois e emite `reward_dropped`. As plantas ficam no lugar.
func die() -> void:
	if phase == Phase.DEAD:
		return
	phase = Phase.DEAD
	_mood = MOOD_HURT
	for plant in _plants:
		plant.target = null
	var quick := _reduced_motion()
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.01 if quick else vanish_time)
	fade.tween_callback(hide)
	_drop_last_battery(quick)


func is_dead() -> bool:
	return phase == Phase.DEAD


# --- Etapas --------------------------------------------------------------------------


func _spawn_guard(patrol: Vector2) -> void:
	var arena := get_parent() as Node2D
	var entry_x := arena_right - guard_entry_inset
	var near := maxf(patrol.x, patrol.y) + _center_x
	var far := minf(patrol.x, patrol.y) + _center_x
	var guard: SpritePatrolEnemy = GUARD_SCENE.instantiate()
	# Pontos em relação a onde ele aparece: primeiro a ponta mais perto da entrada.
	guard.patrol_points = PackedVector2Array(
		[Vector2(near - entry_x, 0), Vector2(far - entry_x, 0)]
	)
	# A rota é calculada no `_ready` do guarda a partir da posição: posiciona antes.
	guard.position = arena.to_local(Vector2(entry_x, arena_floor_y - GUARD_HALF_HEIGHT))
	guard.defeated.connect(_on_guard_defeated)
	arena.add_child(guard)


func _on_guard_defeated() -> void:
	_guards_left -= 1
	if _guards_left > 0 or phase != Phase.GUARDS:
		return
	phase = Phase.AWAKENING
	_mood = MOOD_IDLE
	Analytics.track("chefe_etapa", {"etapa": "acordou"})
	if interlude_requested.get_connections().is_empty():
		_start_normal()
	else:
		interlude_requested.emit()


func _start_normal() -> void:
	phase = Phase.NORMAL
	_mood = MOOD_IDLE
	_fight_id += 1
	_fight_loop(_fight_id)


func _fight_loop(fight_id: int) -> void:
	if not await _pause(first_attack_delay, fight_id):
		return
	while _is_current(fight_id):
		# Atordoada: espera passar antes do próximo ataque.
		while _is_hurt():
			await get_tree().process_frame
			if not _is_current(fight_id):
				return
		_offer_plant_if_due()
		var attack := _pick_attack()
		if attack:
			_current_attack = attack
			_last_attack = attack
			attack.start(self)
			if attack.running:
				await attack.finished
			if not _is_current(fight_id):
				return
			_current_attack = null
			_attacks_since_plant += 1
		if not await _pause(attack_pause, fight_id):
			return


func _is_current(fight_id: int) -> bool:
	return phase == Phase.NORMAL and fight_id == _fight_id and is_inside_tree()


func _pause(seconds: float, fight_id: int) -> bool:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
	return _is_current(fight_id)


## Sorteia um ataque disponível, evitando repetir o último quando há outra opção.
func _pick_attack() -> BossAttack:
	var options := _attacks.filter(func(attack: BossAttack) -> bool: return attack.can_start(self))
	if options.size() > 1:
		options.erase(_last_attack)
	return options.pick_random() if not options.is_empty() else null


## Deixa um canteiro pronto quando não há nenhum esperando e já houve ataques suficientes.
## Escolhe o canteiro mais longe do Garibot, para ele atravessar a arena.
func _offer_plant_if_due() -> void:
	if _attacks_since_plant < attacks_before_plant:
		return
	var dormant: Array[HealingPlant] = []
	for plant in _plants:
		if plant.state in [HealingPlant.PlantState.READY, HealingPlant.PlantState.GROWING]:
			return
		if plant.state == HealingPlant.PlantState.DORMANT:
			dormant.append(plant)
	if dormant.is_empty():
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var chosen := dormant[0]
	if player:
		for plant in dormant:
			var distance := absf(plant.global_position.x - player.global_position.x)
			if distance > absf(chosen.global_position.x - player.global_position.x):
				chosen = plant
	chosen.activate()
	Analytics.track("chefe_planta_pronta", {"planta": str(chosen.name)})


func _on_plant_grown() -> void:
	if phase != Phase.NORMAL:
		return
	progress += 1
	progress_changed.emit(progress, _plants.size())
	_mood = MOOD_HURT
	if progress >= _plants.size():
		phase = Phase.STUNNED
		stop_fight()
		defeated.emit()
		return
	# Interrompe o ataque atual: a nuvem fica atordoada.
	_hurt_until_ms = Time.get_ticks_msec() + int(hurt_time * 1000.0)
	_anchor_x = NAN
	if _current_attack:
		_current_attack.stop()
	# Depois do `stop`: o laço da luta ainda conta o ataque interrompido.
	_attacks_since_plant = 0


func _is_hurt() -> bool:
	return Time.get_ticks_msec() < _hurt_until_ms


## A última pilha cai da nuvem, estrebucha e morre; onde morreu, sai a recompensa.
## Fica sem física (só anima): o Garibot está na cutscene e ela não ataca.
func _drop_last_battery(quick: bool) -> void:
	var arena := get_parent()
	var battery: AcidBatteryEnemy = BATTERY_SCENE.instantiate()
	arena.add_child(battery)
	battery.set_physics_process(false)
	battery.global_position = get_bottom()
	var ground_y := arena_floor_y - BATTERY_HALF_HEIGHT
	var fall := create_tween()
	var falling := fall.tween_property(
		battery, "global_position:y", ground_y, 0.01 if quick else battery_fall_time
	)
	falling.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await fall.finished
	if battery.sprite:
		battery.sprite.play(&"hurt")
	await get_tree().create_timer(battery_struggle_time).timeout
	var at := battery.global_position
	var death := create_tween().set_parallel()
	death.tween_property(battery, "scale", Vector2(1.4, 0.2), battery_death_time)
	death.tween_property(battery, "modulate:a", 0.0, battery_death_time)
	await death.finished
	battery.queue_free()
	reward_dropped.emit(at)


# --- Movimento -----------------------------------------------------------------------


func _drift(delta: float) -> void:
	var speed := move_speed * (0.3 if _is_hurt() else 1.0)
	var target_x := _anchor_x
	if is_nan(target_x):
		target_x = _center_x + sin(_time * TAU / maxf(drift_period, 0.1)) * drift_amplitude
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player:
			target_x = lerpf(target_x, player.global_position.x, follow_player)
	else:
		speed = anchor_speed
	var margin := body_size.x / 2.0
	target_x = clampf(target_x, arena_left + margin, arena_right - margin)
	global_position.x = move_toward(global_position.x, target_x, speed * delta)


## As trepadeiras terminam na parte de baixo da nuvem, do lado de cada canteiro.
func _update_plant_anchors() -> void:
	if phase == Phase.DEAD:
		return
	for plant in _plants:
		var side := signf(plant.global_position.x - global_position.x)
		plant.target_offset = Vector2(side * body_size.x * 0.35, body_size.y * 0.4 + _bob())


func _bob() -> float:
	if _reduced_motion() or phase in [Phase.STUNNED, Phase.DEAD]:
		return 0.0
	return sin(_time * 2.2) * bob_height


func _reduced_motion() -> bool:
	return bool(Settings.get_setting("reduced_motion", false))


# --- Desenho (placeholder) -----------------------------------------------------------


## Nuvem primitiva: uma base retangular e duas bolotas em cima.
func _draw() -> void:
	var w := body_size.x
	var h := body_size.y
	var offset := Vector2(0, _bob())
	var base := Rect2(Vector2(-w / 2.0, -h * 0.1) + offset, Vector2(w, h * 0.6))
	var puffs := [
		Vector3(-w * 0.18, -h * 0.1, h * 0.42),
		Vector3(w * 0.16, -h * 0.18, h * 0.5),
	]
	var color := _body_color()
	draw_rect(base.grow(2.0), outline_color)
	for puff: Vector3 in puffs:
		draw_circle(Vector2(puff.x, puff.y) + offset, puff.z + 2.0, outline_color)
	draw_rect(base, color)
	for puff: Vector3 in puffs:
		draw_circle(Vector2(puff.x, puff.y) + offset, puff.z, color)
	_draw_face(offset + Vector2(0, h * 0.08), h)


func _body_color() -> Color:
	if _mood == MOOD_SLEEP:
		return sleep_color
	var cleanliness := float(progress) / maxi(_plants.size(), 1)
	var color := dirty_color.lerp(clean_color, cleanliness)
	if _mood == MOOD_HURT and not _reduced_motion() and int(_time * 12.0) % 2 == 0:
		color = color.lightened(0.45)  # pisca ao levar o golpe
	return color


func _draw_face(center: Vector2, h: float) -> void:
	var eye := h * 0.09
	var eye_l := center + Vector2(-h * 0.36, 0)
	var eye_r := center + Vector2(h * 0.36, 0)
	var mouth := center + Vector2(0, eye * 2.6)
	match _mood:
		MOOD_SLEEP:
			for at: Vector2 in [eye_l, eye_r]:  # olhos fechados
				draw_line(at - Vector2(eye, 0), at + Vector2(eye, 0), outline_color, 2.0)
		MOOD_HURT:
			for at: Vector2 in [eye_l, eye_r]:  # olhos em "X"
				draw_line(at - Vector2(eye, eye), at + Vector2(eye, eye), outline_color, 2.0)
				draw_line(at + Vector2(-eye, eye), at + Vector2(eye, -eye), outline_color, 2.0)
			draw_rect(Rect2(mouth - Vector2(eye, 1), Vector2(eye * 2.0, 3)), outline_color)
		_:
			var attacking := _mood == MOOD_ATTACK
			var size := eye * (1.3 if attacking else 1.0)
			for side: float in [-1.0, 1.0]:
				var at := eye_r if side > 0.0 else eye_l
				draw_rect(Rect2(at - Vector2(size, size), Vector2(size, size) * 2.0), outline_color)
				draw_rect(
					Rect2(at - Vector2(size, size) * 0.6, Vector2(size, size) * 1.2),
					attack_eye_color if attacking else eye_color
				)
				# Sobrancelha brava
				var outer := at + Vector2(side * size * 1.6, -size * 2.2)
				var inner := at + Vector2(-side * size * 1.0, -size * 1.3)
				draw_line(outer, inner, outline_color, 2.0)
			var mouth_size := Vector2(eye * 2.4, eye * (1.6 if attacking else 0.6))
			draw_rect(Rect2(mouth - mouth_size / 2.0, mouth_size), outline_color)
