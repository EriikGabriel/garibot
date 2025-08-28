extends Control

@export var next_phase: String = ""

func _on_jogar_button_down() -> void:
	SceneManager.game_controller.delete_currrent_gui_scene()
	SceneManager.game_controller.change_2d_scene("res://levels/test_chamber.tscn")

func _on_sair_button_down() -> void:
	get_tree().quit()
