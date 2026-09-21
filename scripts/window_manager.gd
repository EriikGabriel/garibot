extends Node

## Centraliza o atalho de alternância da janela.
## A configuração persistida é atualizada pelo autoload Settings.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("window_mode"):
		var fullscreen_now := DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN
		var target_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_now else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(target_mode)
		if Settings:
			Settings.set_setting("fullscreen", fullscreen_now)
