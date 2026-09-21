extends Node
## Autoload central das preferências do jogador.
## DEFAULTS é a fonte única dos valores iniciais; `settings` contém o estado
## atual e é persistido em user://settings.cfg.

const SAVE_PATH := "user://settings.cfg"
const SAVE_SECTION := "settings"

## Para criar uma preferência: registre o valor aqui, implemente sua aplicação
## em [method apply_setting] e vincule um controle de interface a essa chave.
const DEFAULTS := {
	# Diálogo / Acessibilidade
	"dialog_font_size": 18,
	"text_speed": 1.0,
	"skip_on_click": true,

	# Áudio (0.0 a 1.0)
	"master_volume": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0,

	# Vídeo / Janela
	"fullscreen": true,

	# Gameplay / Acessibilidade
	"screen_shake": true,
	"subtitles": true,
	"high_contrast": false,
	"brightness": 1.0,
	"reduced_motion": false,
	# Cada ação guarda uma tecla física escolhida pelo jogador.
	"keybinds": {
		"move_left": KEY_A,
		"move_right": KEY_D,
		"move_up": KEY_SPACE,
		"attack": KEY_SHIFT,
	},
}

var settings: Dictionary = DEFAULTS.duplicate(true)

signal setting_changed(setting_name: String, value: Variant)

var _save_timer: Timer

func _ready() -> void:
	load_settings()
	apply_all()

	# Consolida alterações contínuas de sliders em uma única gravação.
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.5
	_save_timer.timeout.connect(save_settings)
	add_child(_save_timer)

	# Dialogic é carregado depois deste autoload; aguarda um frame para conectá-lo.
	get_tree().process_frame.connect(_setup_dialogic_hooks, CONNECT_ONE_SHOT)

func _setup_dialogic_hooks() -> void:
	if not has_node("/root/Dialogic"):
		return
	var dialogic: Node = get_node("/root/Dialogic")
	if dialogic.has_subsystem("Styles"):
		dialogic.Styles.style_changed.connect(_on_dialogic_style_changed)
	# Reaplica as preferências de diálogo após o carregamento do plugin.
	apply_setting("dialog_font_size", settings["dialog_font_size"])
	apply_setting("text_speed", settings["text_speed"])
	apply_setting("skip_on_click", settings["skip_on_click"])

func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return

	for key in settings.keys():
		if cfg.has_section_key(SAVE_SECTION, key):
			settings[key] = cfg.get_value(SAVE_SECTION, key)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in settings.keys():
		cfg.set_value(SAVE_SECTION, key, settings[key])
	var error := cfg.save(SAVE_PATH)
	if error != OK:
		push_warning("Settings: não foi possível salvar as preferências (erro %d)." % error)

func reset_settings() -> void:
	for key in DEFAULTS:
		set_setting(key, DEFAULTS[key])

func get_setting(key: String, default: Variant = null) -> Variant:
	if settings.has(key):
		return settings[key]
	return default

func set_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		settings[key] = value
	elif settings[key] == value:
		return
	settings[key] = value
	apply_setting(key, value)
	setting_changed.emit(key, value)
	# Consolida gravações durante uso contínuo da interface.
	if _save_timer:
		_save_timer.start()

## Aplica todas as configurações atuais.
func apply_all() -> void:
	for key in settings.keys():
		apply_setting(key, settings[key])

## Aplica uma configuração. Inclua aqui toda nova chave que tenha efeito imediato.
func apply_setting(key: String, value: Variant) -> void:
	match key:
		"dialog_font_size":
			_apply_dialog_font_size(value)
		"text_speed":
			_apply_text_speed(value)
		"skip_on_click":
			_apply_skip_on_click(value)
		"master_volume":
			_set_bus_volume("Master", value)
		"music_volume":
			_set_bus_volume("Music", value)
		"sfx_volume":
			_set_bus_volume("Sfx", value)
		"fullscreen":
			_apply_fullscreen(value)
		"keybinds":
			_apply_keybinds(value)
		"screen_shake", "subtitles", "high_contrast", "reduced_motion", "brightness":
			# Os consumidores recebem a atualização pelo sinal setting_changed.
			pass

func _get_dialogic() -> Node:
	return get_node_or_null("/root/Dialogic")

func _apply_dialog_font_size(size: int) -> void:
	var dialogic := _get_dialogic()
	if not dialogic or not dialogic.has_subsystem("Styles"):
		return
	if dialogic.Styles.has_active_layout_node():
		var layout = dialogic.Styles.get_layout_node()
		if layout:
			layout.set("global_font_size", int(size))
			if layout.has_method("apply_export_overrides"):
				layout.apply_export_overrides()

func _on_dialogic_style_changed(_info: Dictionary) -> void:
	# Quando um estilo de diálogo é (re)criado, reaplica o tamanho da fonte.
	_apply_dialog_font_size(settings["dialog_font_size"])

func _apply_text_speed(speed: float) -> void:
	var dialogic := _get_dialogic()
	if not dialogic or not dialogic.has_subsystem("Text"):
		return
	# 1.0 é normal; valores maiores revelam o texto mais rapidamente.
	var letter_speed := 0.01 / maxf(speed, 0.05)
	dialogic.Text.update_text_speed(letter_speed)

func _apply_skip_on_click(skippable: bool) -> void:
	var dialogic := _get_dialogic()
	if not dialogic or not dialogic.has_subsystem("Text"):
		return
	dialogic.Text.set_text_reveal_skippable(skippable, true)

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(clampf(linear, 0.0, 1.0)))

func get_bus_volume(bus_name: String) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))

func _apply_fullscreen(enabled: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func set_keybind(action: StringName, physical_keycode: int) -> void:
	if not InputMap.has_action(action):
		push_warning("Settings: ação de entrada inexistente: %s" % action)
		return
	var keybinds: Dictionary = settings["keybinds"].duplicate(true)
	keybinds[String(action)] = physical_keycode
	set_setting("keybinds", keybinds)

func get_keybind(action: StringName) -> int:
	var keybinds: Dictionary = settings.get("keybinds", {})
	return int(keybinds.get(String(action), KEY_NONE))

func _apply_keybinds(keybinds: Dictionary) -> void:
	for action_name in keybinds:
		var action := StringName(action_name)
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var input := InputEventKey.new()
		input.physical_keycode = int(keybinds[action_name])
		InputMap.action_add_event(action, input)

func get_default(key: String) -> Variant:
	return DEFAULTS.get(key, null)
