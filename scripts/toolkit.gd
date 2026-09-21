extends Node

## Utilitários globais pequenos, sem dependência de cenas específicas.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_fullscreen()

## Alterna a janela e mantém a preferência persistente sincronizada.
func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if Settings:
			Settings.set_setting("fullscreen", false)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		if Settings:
			Settings.set_setting("fullscreen", true)

## Representa um ataque para que hitboxes não dependam de tipos de inimigo.
class Attack:
	var damage: float

	func _init(value: float) -> void:
		damage = value
