extends Node
## Autoload responsável por gerenciar todas as configurações do jogo.
## Modular e extensível: cada setting tem um "nome de chave", um valor,
## e (opcionalmente) um método de aplicação definido em [method apply_setting].
## As configurações são persistidas em um ConfigFile em user://settings.cfg

const SAVE_PATH := "user://settings.cfg"

## Seção do ConfigFile onde os valores ficam armazenados.
const SAVE_SECTION := "settings"

# ------------------------------------------------------------------ #
#  Definição das configurações (nome da chave -> valor padrão)
#  Para adicionar uma nova configuração: adicione aqui, crie um setter
#  (ou use o método genérico) e registre a UI no menu de configurações.
# ------------------------------------------------------------------ #
var settings := {
	# Diálogo / Acessibilidade
	"dialog_font_size": 18,          # Tamanho da fonte dos diálogos
	"text_speed": 1.0,               # Velocidade de revelação do texto (1.0 = normal)
	"skip_on_click": true,           # Pular revelação do texto ao clicar

	# Áudio (0.0 a 1.0)
	"master_volume": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0,

	# Vídeo / Janela
	"fullscreen": true,

	# Gameplay / Acessibilidade
	"screen_shake": true,
	"subtitles": true,
}

signal setting_changed(setting_name: String, value: Variant)

var _save_timer: Timer

func _ready() -> void:
	load_settings()
	apply_all()

	# Salva de forma "debounced" para não gravar a cada frame durante o arrasto
	# de um slider.
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.5
	_save_timer.timeout.connect(save_settings)
	add_child(_save_timer)

	# Aguarda a árvore estar estável (após todos os autoloads) antes de
	# conectar ganchos ao Dialogic, que é inicializado depois deste autoload.
	get_tree().process_frame.connect(_setup_dialogic_hooks, CONNECT_ONE_SHOT)

func _setup_dialogic_hooks() -> void:
	if not has_node("/root/Dialogic"):
		return
	var dialogic: Node = get_node("/root/Dialogic")
	if dialogic.has_subsystem("Styles"):
		dialogic.Styles.style_changed.connect(_on_dialogic_style_changed)
	# Aplica as configurações de diálogo agora que o Dialogic está disponível.
	apply_setting("dialog_font_size", settings["dialog_font_size"])
	apply_setting("text_speed", settings["text_speed"])
	apply_setting("skip_on_click", settings["skip_on_click"])

# ------------------------------------------------------------------ #
#  Persistência
# ------------------------------------------------------------------ #

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
	cfg.save(SAVE_PATH)

func reset_settings() -> void:
	for key in settings.keys():
		set_setting(key, _default_value(key))

# ------------------------------------------------------------------ #
#  Getters / Setters
# ------------------------------------------------------------------ #

func _default_value(key: String) -> Variant:
	# Valores padrão são derivados do dicionário inicial.
	# Reconstruímos um dicionário de defaults separadamente para poder resetar.
	return get_default(key)

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
	# Persistência "debounced": consolida gravações durante uso contínuo da UI.
	if _save_timer:
		_save_timer.start()

# ------------------------------------------------------------------ #
#  Aplicação
# ------------------------------------------------------------------ #

## Aplica todas as configurações atuais.
func apply_all() -> void:
	for key in settings.keys():
		apply_setting(key, settings[key])

## Aplica uma configuração específica. Extensível: adicione novos casos aqui.
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
		"screen_shake":
			# Placeholder: adicione lógica de screen shake aqui se necessário.
			pass
		"subtitles":
			# Placeholder: controle de legendas (se for implementado no futuro).
			pass

# ------------------------- Diálogo ------------------------------- #

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
	# 1.0 = normal (mesma letra_speed do projeto); valores maiores aceleram.
	var letter_speed := 0.01 / maxf(speed, 0.05)
	dialogic.Text.update_text_speed(letter_speed)

func _apply_skip_on_click(skippable: bool) -> void:
	var dialogic := _get_dialogic()
	if not dialogic or not dialogic.has_subsystem("Text"):
		return
	dialogic.Text.set_text_reveal_skippable(skippable, true)

# ------------------------- Áudio -------------------------------- #

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

# ------------------------- Vídeo -------------------------------- #

func _apply_fullscreen(enabled: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

# ------------------------------------------------------------------ #
#  Utilitários de "default" (para reset)
# ------------------------------------------------------------------ #

const DEFAULTS := {
	"dialog_font_size": 18,
	"text_speed": 1.0,
	"skip_on_click": true,
	"master_volume": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"fullscreen": true,
	"screen_shake": true,
	"subtitles": true,
}

func get_default(key: String) -> Variant:
	return DEFAULTS.get(key, settings.get(key))
