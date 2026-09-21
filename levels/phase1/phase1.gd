extends Node2D

var _reee_count := 0
var _intro_finished := false
var _learned_walk := false
var _learned_jump := false
var _reee_total := 0
@onready var objective_label: Label = $HUD/Objective
@onready var tutorial_label: Label = $HUD/Tutorial
@onready var hud_panels = $HUD/PixelPanels
@onready var player = $Player

func _ready() -> void:
	add_to_group("phase1_level")
	Settings.setting_changed.connect(_on_accessibility_setting_changed)
	_apply_accessibility_preferences()
	var items := get_tree().get_nodes_in_group("phase1_reee")
	_reee_total = items.size()
	for item in items:
		item.monitoring = false
		item.collected.connect(_on_reee_collected)
	for npc in [get_node("Garidog"), get_node("CorreioBo"), get_node("Morador")]:
		npc.get_node("TalkArea").monitoring = false
	var cutscene: CutscenePlayer = get_node_or_null("CutscenePlayer")
	if cutscene != null:
		cutscene.finished.connect(_on_intro_finished)
		cutscene.run()
	_update_hud()

func _on_accessibility_setting_changed(setting_name: String, _value: Variant) -> void:
	if setting_name in ["high_contrast", "dialog_font_size"]:
		_apply_accessibility_preferences()

func _apply_accessibility_preferences() -> void:
	var high_contrast := bool(Settings.get_setting("high_contrast", false))
	var font_size := int(Settings.get_setting("dialog_font_size", 18))
	objective_label.add_theme_font_size_override("font_size", maxi(17, font_size))
	tutorial_label.add_theme_font_size_override("font_size", maxi(18, font_size))
	var foreground := Color.WHITE if high_contrast else Color("#f5edca")
	objective_label.add_theme_color_override("font_color", foreground)
	tutorial_label.add_theme_color_override("font_color", foreground)

func _process(_delta: float) -> void:
	if not _intro_finished:
		return
	if not _learned_walk and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")):
		_learned_walk = true
		_update_hud()
	if _learned_walk and not _learned_jump and Input.is_action_just_pressed("move_up"):
		_learned_jump = true
		_update_hud()

func _on_intro_finished() -> void:
	_intro_finished = true
	for item in get_tree().get_nodes_in_group("phase1_reee"):
		item.monitoring = true
	for npc in [get_node("Garidog"), get_node("CorreioBo"), get_node("Morador")]:
		npc.get_node("TalkArea").monitoring = true
	_update_hud()

func _on_reee_collected(item_name: String) -> void:
	_reee_count += 1
	$World.register_reee()
	_update_hud()
	if _reee_count == 1:
		_start_dialog("res://dialogic/timelines/fase1/reee.dtl")
	elif _reee_count == _reee_total:
		$Garidog.global_position = player.global_position + Vector2(-105, 14)
		$Morador.global_position = player.global_position + Vector2(105, 14)
		_start_dialog("res://dialogic/timelines/fase1/conclusao.dtl")

func _start_dialog(timeline_path: String) -> void:
	Phase1Dialogue.start(timeline_path, self)

func _update_hud() -> void:
	if not is_instance_valid(objective_label):
		return
	objective_label.text = "REEE recolhidos: %d/%d" % [_reee_count, _reee_total]
	hud_panels.set_progress(_reee_count, _reee_total)
	if not _intro_finished:
		tutorial_label.text = "Sinal de alerta recebido..."
	elif not _learned_walk:
		tutorial_label.text = "Primeiro, ande pela rua: A/D ou setas esquerda/direita."
	elif not _learned_jump:
		tutorial_label.text = "Agora pule a poça de óleo: Espaço, W ou seta para cima."
	elif _reee_count == 0:
		tutorial_label.text = "Recolha o primeiro celular para conhecer o lixo eletrônico."
	elif _reee_count < _reee_total:
		tutorial_label.text = "Continue limpando a vila: procure REEE nas ruas, no parque e no rio."
	else:
		tutorial_label.text = "A vila está mais limpa! Converse com os moradores para continuar."
