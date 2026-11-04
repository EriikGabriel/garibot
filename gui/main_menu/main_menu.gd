extends Control

## Menu inicial. "Jogar" passa pelo assistente de configurações antes da fase.

@export var settings_scene: PackedScene


func _ready() -> void:
	$Card/Content/Play.grab_focus()


func _on_play_pressed() -> void:
	GameController.instance.change_gui_scene(settings_scene.resource_path)


func _on_settings_pressed() -> void:
	GameController.instance.change_gui_scene(settings_scene.resource_path)


func _on_quit_pressed() -> void:
	get_tree().quit()
