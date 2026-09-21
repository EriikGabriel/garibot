extends HBoxContainer
## Linha de remapeamento por teclado. Clique em "Alterar" e pressione a tecla
## desejada; Esc cancela a captura sem modificar a preferência.

@export var label_text := "Ação"
@export var action_name: StringName

@onready var label: Label = %Label
@onready var button: Button = %Button

var _capturing := false

func _ready() -> void:
	label.text = label_text
	button.pressed.connect(_start_capture)
	Settings.setting_changed.connect(_on_setting_changed)
	_update_button()

func _start_capture() -> void:
	_capturing = true
	button.text = "Pressione uma tecla…"
	button.grab_focus()

func _input(event: InputEvent) -> void:
	# Captura antes do botão focado processar Espaço/Enter como ativação.
	if not _capturing or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	get_viewport().set_input_as_handled()
	_capturing = false
	if key_event.keycode != KEY_ESCAPE:
		var selected_key := key_event.physical_keycode
		if selected_key == KEY_NONE:
			selected_key = key_event.keycode
		if selected_key != KEY_NONE:
			Settings.set_keybind(action_name, selected_key)
	_update_button()

func _on_setting_changed(setting_name: String, _value: Variant) -> void:
	if setting_name == "keybinds":
		_update_button()

func _update_button() -> void:
	if not _capturing:
		var key := Settings.get_keybind(action_name)
		button.text = OS.get_keycode_string(key) if key != KEY_NONE else "Não definido"
