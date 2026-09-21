extends HBoxContainer
## Controle reutilizável que exibe um Rótulo + CheckBox vinculado a uma
## configuração booleana do autoload Settings (via settings_key).

signal toggle_changed(key: String, value: bool)

@export var label_text: String = "Setting"
@export var settings_key: String = ""

@onready var label: Label = %Label
@onready var check: CheckBox = %Toggle

func _ready() -> void:
	label.text = label_text
	check.toggled.connect(_on_toggled)
	check.button_pressed = bool(Settings.get_setting(settings_key, false))

func _on_toggled(pressed: bool) -> void:
	Settings.set_setting(settings_key, pressed)
	toggle_changed.emit(settings_key, pressed)
