extends Node2D

## Fase 1: tutorial guiado por áreas, coleta de REEE e conclusão com minigames.

const MINIGAMES_SCENE := preload("res://levels/phase1/minigames/phase1_minigames.tscn")
const CONCLUSION_TIMELINE := "res://dialogic/timelines/fase1/conclusao.dtl"
## Fala do Garibot ao encostar na barreira sem o REEE do tutorial.
const GATE_REMARK_TIMELINE := "res://dialogic/timelines/fase1/garibot_celular.dtl"
## Peso dos REEE na restauração; o restante vem do bônus de atenção e atividades.
const REEE_RESTORATION_WEIGHT := 0.8
## Atividades chamadas pelos diálogos via `[signal arg="minigame:<id>"]`.
const MINIGAME_PAGES := {
	"triagem": [Phase1Minigames.PAGE_SORTING],
	"associacao": [Phase1Minigames.PAGE_MATCHING],
	"cruzadinha": [Phase1Minigames.PAGE_CROSSWORD],
}

@export var fall_reset_y := 380.0
## Limites da câmera do Garibot (esquerda, topo, largura, altura).
@export var camera_limits := Rect2i(-300, -650, 5700, 1030)
## Bônus de restauração por resposta certa ou atividade concluída (máx. 1 - peso dos REEE).
@export var bonus_per_reward := 0.04
## Pausa entre a bateria acabar e o Garibot renascer (s).
@export var respawn_delay := 1.4
## Ao abrir um diálogo, ignora o botão de avançar por este tempo (s). O Espaço também
## é o pulo: sem isso, quem chega pulando no NPC pula as primeiras falas.
@export var dialogue_input_block := 0.5
## Intervalo mínimo entre o fim de um diálogo/atividade e a próxima conversa com NPC (s).
@export var npc_dialogue_cooldown := 0.6
## Distância depois do REEE do tutorial a partir da qual o tutorial pede para voltar (px).
@export var tutorial_reee_hint_distance := 40.0
## Distância da barreira em que encostar nela conta como "tentar passar" (px).
@export var gate_remark_distance := 24.0
## Intervalo mínimo entre duas falas do Garibot na barreira (s).
@export var gate_remark_cooldown := 8.0

var _reee_count := 0
var _reee_total := 0
var _zone_index := 0
var _intro_finished := false
var _learned_walk := false
var _learned_jump := false
var _dialogue_active := false
var _conclusion_started := false
var _conclusion_dialogue_active := false
var _minigames_active := false
var _phase_completed := false
var _bonus := 0.0
## Último ponto seguro: início da fase ou marcador da zona mais avançada alcançada.
var _respawn_point := Vector2.ZERO
var _respawn_zone := 0
## Telemetria: início da fase, mortes e atividade (minigame) em andamento.
var _phase_start_ms := 0
var _deaths := 0
var _activity_id := ""
var _activity_start_ms := 0
var _pending_minigame := ""
## A explicação do primeiro REEE espera o diálogo ou a atividade em andamento terminar.
var _pending_reee_cutscene := false
var _npc_dialogue_ready_ms := 0
var _tutorial_reee_collected := false
## O Garibot passou do REEE do tutorial sem pegá-lo.
var _passed_tutorial_reee := false
var _gate_remark_ready_ms := 0
var _pending_tutorial_speech := false
var _last_narrated_tutorial := ""

@onready var player: Player = $Player
@onready var restoration: RestorationProgress = $Restoration
@onready var intro_cutscene: CutscenePlayer = $CutscenePlayer
@onready var reee_cutscene: CutscenePlayer = $ReeeCutscene
@onready var objective_label: Label = $HUD/Objective
@onready var tutorial_label: Label = $HUD/Tutorial
@onready var hud_panels: CollectibleProgressHud = $HUD/PixelPanels
@onready var battery_hud: BatteryHealthHud = $HUD/Battery
## REEE do tutorial, ao lado do Garidog: só ele abre a explicação (o Garidog não sai do
## lugar, então com outro REEE a conversa aconteceria fora da tela).
@onready var tutorial_reee: AreaCollectible = $ReeeCelular
## Barreira invisível depois do Garidog; abre quando o REEE do tutorial é coletado.
@onready var tutorial_gate: StaticBody2D = $TutorialGate
@onready var talking_npcs: Array[Phase1Npc] = [$Garidog, $CorreioBo, $Morador, $Crianca, $DonaLia, $Pipa]


func _ready() -> void:
	$HUD.show()
	_setup_camera()
	_respawn_point = player.position
	_respawn_zone = _current_zone()
	player.health.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)
	_phase_start_ms = Time.get_ticks_msec()
	Analytics.set_context({"fase": "fase1", "zona": _zone_title(_respawn_zone)})
	Analytics.set_tracked_node(player)
	Analytics.track("fase_inicio")
	battery_hud.set_charge(int(player.health.health), int(player.health.max_health))
	var items := get_tree().get_nodes_in_group("phase1_reee")
	_reee_total = items.size()
	for item: AreaCollectible in items:
		item.monitoring = false
		item.collected.connect(_on_reee_collected.bind(item == tutorial_reee))
	_set_npcs_listening(false)
	restoration.set_value(0.0, false)
	Settings.setting_changed.connect(_on_setting_changed)
	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)
	Dialogic.signal_event.connect(_on_dialogue_signal)
	intro_cutscene.started.connect(_on_cinematic_started)
	intro_cutscene.finished.connect(_on_intro_finished)
	reee_cutscene.started.connect(_on_cinematic_started)
	reee_cutscene.finished.connect(_resume_tutorial)
	_apply_accessibility_preferences()
	_set_tutorial_visible(false)
	_update_hud()
	intro_cutscene.run()


func _process(_delta: float) -> void:
	if _tutorial_blocked():
		return
	if (
		not _learned_walk
		and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"))
	):
		_learned_walk = true
		_update_hud()
	if _learned_walk and not _learned_jump and Input.is_action_just_pressed("move_up"):
		_learned_jump = true
		_update_hud()
	var passed := (
		not _tutorial_reee_collected
		and player.position.x > tutorial_reee.position.x + tutorial_reee_hint_distance
	)
	if passed != _passed_tutorial_reee:
		_passed_tutorial_reee = passed
		_update_hud()
	if passed:
		_check_gate_remark()
	var zone := _current_zone()
	if zone != _zone_index:
		_zone_index = zone
		_update_hud()
		Analytics.set_context({"zona": _zone_title(zone)})
		Analytics.track("zona_entrou")
	if zone > _respawn_zone and player.is_on_floor():
		_respawn_zone = zone
		_respawn_point = $Flow.get_child(zone).position
	if _can_conclude():
		_begin_conclusion()


func _physics_process(_delta: float) -> void:
	if _intro_finished and player.position.y > fall_reset_y:
		_return_to_river_bank()


## Usada pelo CutscenePlayer para abrir diálogos nos balões da fase.
func start_dialogue(timeline_path: String) -> void:
	Phase1Dialogue.start(timeline_path, self)


## Chamado pelos NPCs. Só abre a conversa quando nada mais está acontecendo e
## devolve `true` se ela começou.
func try_start_npc_dialogue(timeline_path: String) -> bool:
	if not _can_start_npc_dialogue():
		return false
	# Reserva já: o Dialogic só emite `timeline_started` quando o layout fica pronto,
	# e outro NPC (as áreas do Morador e da Criança se sobrepõem) poderia abrir junto.
	_dialogue_active = true
	player.has_control = false
	player.move_velocity = 0.0
	if not Phase1Dialogue.start(timeline_path, self):
		_dialogue_active = false
		player.has_control = true
		return false
	return true


## O Garibot comenta quando empurra a barreira sem ter pegado o REEE do tutorial.
func _check_gate_remark() -> void:
	var at_gate := (
		player.is_on_wall()
		and absf(player.position.x - tutorial_gate.position.x) <= gate_remark_distance
	)
	if not at_gate or Time.get_ticks_msec() < _gate_remark_ready_ms:
		return
	if try_start_npc_dialogue(GATE_REMARK_TIMELINE):
		_gate_remark_ready_ms = Time.get_ticks_msec() + int(gate_remark_cooldown * 1000.0)


func _can_start_npc_dialogue() -> bool:
	return (
		not _tutorial_blocked()
		and not _pending_reee_cutscene
		and Dialogic.current_timeline == null
		and Time.get_ticks_msec() >= _npc_dialogue_ready_ms
		and player.has_control
		and not player.in_cutscene
		and player.is_on_floor()
	)


func _setup_camera() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = camera_limits.position.x
	camera.limit_top = camera_limits.position.y
	camera.limit_right = camera_limits.end.x
	camera.limit_bottom = camera_limits.end.y


func _current_zone() -> int:
	var zone := 0
	for marker: Marker2D in $Flow.get_children():
		if player.position.x >= marker.position.x:
			zone = marker.get_index()
	return zone


func _can_conclude() -> bool:
	return (
		not _conclusion_started
		and _reee_count == _reee_total
		and player.position.x >= $Flow/Finish.position.x
		and player.is_on_floor()
	)


## Cair no rio devolve o Garibot à margem, sem perder as coletas.
func _return_to_river_bank() -> void:
	Analytics.track("queda_rio")
	player.position = $RiverCheckpoint.position
	player.velocity = Vector2.ZERO
	player.move_velocity = 0.0
	player.jump_velocity = 0.0
	player.get_node("Camera2D").reset_smoothing()


func _zone_title(index: int) -> String:
	var marker := $Flow.get_child(index)
	return str(marker.get_meta("title", marker.name))


func _on_player_damaged(amount: float, source: String) -> void:
	Analytics.track(
		"dano", {"quantidade": amount, "fonte": source, "bateria": int(player.health.health)}
	)


func _on_player_health_changed(health: float, max_health: float) -> void:
	battery_hud.set_charge(ceili(health), int(max_health))


## Bateria zerada: o Garibot "recarrega" e volta ao último ponto seguro,
## sem perder os REEE coletados.
func _on_player_died() -> void:
	_deaths += 1
	# Adiado: a morte é avisada no meio do dano; assim o "dano" fatal vem antes na planilha.
	Analytics.track.call_deferred("morte", {"mortes": _deaths})
	_set_tutorial_visible(false)
	Speech.speak("O Garibot ficou sem bateria! Recarregando no último ponto seguro.", "instruction")
	await get_tree().create_timer(respawn_delay).timeout
	player.revive(_respawn_point)
	Analytics.track("renascimento")
	_resume_tutorial()


func _set_npcs_listening(enabled: bool) -> void:
	for npc in talking_npcs:
		npc.get_node("TalkArea").set_deferred("monitoring", enabled)


func _on_setting_changed(setting_name: String, _value: Variant) -> void:
	if setting_name in ["high_contrast", "dialog_font_size"]:
		_apply_accessibility_preferences()


func _apply_accessibility_preferences() -> void:
	var font_size := int(Settings.get_setting("dialog_font_size", 18))
	var foreground := (
		Color.WHITE if Settings.get_setting("high_contrast", false) else Color("#f5edca")
	)
	objective_label.add_theme_font_size_override("font_size", maxi(17, font_size))
	tutorial_label.add_theme_font_size_override("font_size", maxi(18, font_size))
	objective_label.add_theme_color_override("font_color", foreground)
	tutorial_label.add_theme_color_override("font_color", foreground)


func _on_intro_finished() -> void:
	_intro_finished = true
	for item in get_tree().get_nodes_in_group("phase1_reee"):
		item.set_deferred("monitoring", true)
	_set_npcs_listening(true)
	_resume_tutorial()


func _on_cinematic_started() -> void:
	Speech.stop()
	_pending_tutorial_speech = true
	_last_narrated_tutorial = ""
	_set_tutorial_visible(false)


func _on_dialogue_started() -> void:
	_dialogue_active = true
	player.has_control = false
	Dialogic.Inputs.block_input(dialogue_input_block)
	_on_cinematic_started()


func _on_dialogue_ended() -> void:
	_dialogue_active = false
	_delay_next_npc_dialogue()
	if not _pending_minigame.is_empty() and not _conclusion_dialogue_active:
		var minigame_id := _pending_minigame
		_pending_minigame = ""
		# Já bloqueia o tutorial e os NPCs: a atividade só abre no fim do quadro.
		_minigames_active = true
		_open_minigame.call_deferred(minigame_id)
		return
	# Espera o Dialogic e a cutscene terminarem a limpeza antes de retomar o HUD.
	_resume_tutorial.call_deferred()


## Sinais emitidos pelas timelines: `acerto` premia a resposta certa e
## `minigame:<id>` abre a atividade quando o diálogo terminar.
func _on_dialogue_signal(argument: String) -> void:
	if argument == "acerto":
		_add_bonus()
	elif argument.begins_with("minigame:"):
		_pending_minigame = argument.trim_prefix("minigame:")


func _add_bonus() -> void:
	GameAudio.play_sound(&"correct")
	_bonus = minf(_bonus + bonus_per_reward, 1.0 - REEE_RESTORATION_WEIGHT)
	_refresh_restoration()


func _refresh_restoration() -> void:
	var base := float(_reee_count) / maxi(_reee_total, 1) * REEE_RESTORATION_WEIGHT
	# Com todos os REEE a vila fica 100% recuperada, independentemente do bônus.
	restoration.set_value(1.0 if _reee_count == _reee_total else base + _bonus)


func _open_minigame(minigame_id: String) -> void:
	if not MINIGAME_PAGES.has(minigame_id):
		push_error("Minigame desconhecido: %s" % minigame_id)
		_minigames_active = false
		_resume_tutorial()
		return
	_track_activity_start(minigame_id)
	_minigames_active = true
	player.has_control = false
	var minigames: Phase1Minigames = MINIGAMES_SCENE.instantiate()
	minigames.pages.assign(MINIGAME_PAGES[minigame_id])
	minigames.final_title = "Muito bem!"
	minigames.final_message = "Você está cada vez mais perto de salvar a vila."
	minigames.final_button_text = "Continuar"
	minigames.finished.connect(_on_activity_finished)
	add_child(minigames)


func _on_activity_finished(perfect: bool) -> void:
	_track_activity_end(perfect)
	_minigames_active = false
	_delay_next_npc_dialogue()
	if perfect:
		_add_bonus()
	player.has_control = true
	_resume_tutorial()


func _delay_next_npc_dialogue() -> void:
	_npc_dialogue_ready_ms = Time.get_ticks_msec() + int(npc_dialogue_cooldown * 1000.0)


func _on_reee_collected(item_name: String, is_tutorial: bool) -> void:
	GameAudio.play_sound(&"collect")
	_reee_count += 1
	Analytics.track("reee_coletado", {"item": item_name, "total": _reee_count})
	_refresh_restoration()
	if is_tutorial:
		_tutorial_reee_collected = true
		_passed_tutorial_reee = false
		tutorial_gate.queue_free()
		_pending_reee_cutscene = true
		_run_pending_reee_cutscene()
	_update_hud()


## Abre a explicação do primeiro REEE só quando nenhum diálogo, cutscene ou atividade
## está em andamento; senão o diálogo dela substituiria o que está na tela.
func _run_pending_reee_cutscene() -> bool:
	if not _pending_reee_cutscene or _tutorial_blocked():
		return false
	_pending_reee_cutscene = false
	reee_cutscene.run()
	return true


func _begin_conclusion() -> void:
	_conclusion_started = true
	_conclusion_dialogue_active = true
	player.position = $FinishPoint.position
	player.velocity = Vector2.ZERO
	player.move_velocity = 0.0
	player.has_control = false
	$Garidog.position = $FinishPoint.position + Vector2(-105, 14)
	$Morador.position = $FinishPoint.position + Vector2(105, 14)
	$Garidog/TalkArea.set_deferred("monitoring", false)
	$Morador/TalkArea.set_deferred("monitoring", false)
	Dialogic.timeline_ended.connect(_on_conclusion_finished, CONNECT_ONE_SHOT)
	start_dialogue(CONCLUSION_TIMELINE)


func _on_conclusion_finished() -> void:
	_conclusion_dialogue_active = false
	_minigames_active = true
	var minigames: Phase1Minigames = MINIGAMES_SCENE.instantiate()
	minigames.pages.assign([Phase1Minigames.PAGE_CROSSWORD])
	_track_activity_start("cruzadinha")
	minigames.finished.connect(_on_minigames_finished)
	add_child(minigames)


func _on_minigames_finished(perfect: bool) -> void:
	_track_activity_end(perfect)
	Analytics.track(
		"fase_concluida",
		{
			"tempo_total_s": snappedf((Time.get_ticks_msec() - _phase_start_ms) / 1000.0, 0.1),
			"mortes": _deaths,
		}
	)
	# Cópia automática da planilha a cada fase concluída (sobrescreve a anterior).
	Analytics.export_data(false, "ultima_fase_concluida")
	_phase_completed = true
	_minigames_active = false
	player.has_control = true
	_resume_tutorial()


func _tutorial_blocked() -> bool:
	return (
		not _intro_finished
		or player.is_dead()
		or intro_cutscene.is_running()
		or reee_cutscene.is_running()
		or _dialogue_active
		or _conclusion_dialogue_active
		or _minigames_active
	)


func _set_tutorial_visible(value: bool) -> void:
	tutorial_label.visible = value
	hud_panels.set_tutorial_visible(value)


func _resume_tutorial() -> void:
	if _tutorial_blocked() or _run_pending_reee_cutscene():
		return
	player.has_control = true
	_set_tutorial_visible(true)
	_update_hud()


func _update_hud() -> void:
	objective_label.text = "REEE recolhidos: %d/%d" % [_reee_count, _reee_total]
	hud_panels.set_progress(_reee_count, _reee_total)
	if not _intro_finished:
		tutorial_label.text = ""
		return
	var previous_text := tutorial_label.text
	tutorial_label.text = _tutorial_text()
	if tutorial_label.text != previous_text:
		_pending_tutorial_speech = true
	_narrate_tutorial_when_ready()


func _tutorial_text() -> String:
	if _phase_completed:
		return "Missão concluída! Explore a vila recuperada e veja o parque e o rio."
	if not _learned_walk:
		return "Primeiro, ande pela rua: A/D ou setas esquerda/direita."
	if not _learned_jump:
		return "Pule os bloqueios: Espaço, W ou seta para cima. Segure para pular mais alto."
	if _passed_tutorial_reee:
		return "Ficou um celular para trás! Volte e recolha-o perto do Garidog para seguir."
	return _collection_tutorial_text()


func _collection_tutorial_text() -> String:
	if _reee_count == _reee_total:
		return "Todos os REEE recolhidos! Siga para a praça de reciclagem, depois do rio."
	if _zone_index == $Flow/Finish.get_index():
		return (
			"Faltam %d REEE. Volte e procure nas varandas, no mirante e nas pedras do rio."
			% (_reee_total - _reee_count)
		)
	return str($Flow.get_child(_zone_index).get_meta("hint", ""))


func _narrate_tutorial_when_ready() -> void:
	if (
		not _pending_tutorial_speech
		or _tutorial_blocked()
		or not tutorial_label.is_visible_in_tree()
	):
		return
	_pending_tutorial_speech = false
	if tutorial_label.text != _last_narrated_tutorial:
		_last_narrated_tutorial = tutorial_label.text
		Speech.speak(tutorial_label.text, "instruction")


func _track_activity_start(activity: String) -> void:
	_activity_id = activity
	_activity_start_ms = Time.get_ticks_msec()
	Analytics.track("minigame_inicio", {"atividade": activity})


func _track_activity_end(perfect: bool) -> void:
	(
		Analytics
		. track(
			"minigame_fim",
			{
				"atividade": _activity_id,
				"perfeito": perfect,
				"duracao_s": snappedf((Time.get_ticks_msec() - _activity_start_ms) / 1000.0, 0.1),
			}
		)
	)
