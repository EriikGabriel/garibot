extends Control

@export var next_phase: PackedScene

func _on_jogar_button_down() -> void:
	SceneManager.game_controller.delete_currrent_gui_scene()
	SceneManager.game_controller.change_2d_scene(next_phase)

func _on_sair_button_down() -> void:
	get_tree().quit()
