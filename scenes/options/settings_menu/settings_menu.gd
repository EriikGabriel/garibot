extends Control
## Menu de configurações exibido antes de iniciar a fase.
## Permite ajustar acessibilidade (fonte, velocidade de texto), áudio e vídeo.
## Ao pressionar "Começar", inicia a fase definida em [member next_phase].

@export var next_phase: PackedScene
@export var back_to_menu: String = "res://gui/main_menu/main_menu.tscn"

func _on_comecar_button_down() -> void:
	Settings.save_settings()
	if SceneManager.game_controller:
		SceneManager.game_controller.delete_current_gui_scene()
		SceneManager.game_controller.change_2d_scene(next_phase)

func _on_voltar_button_down() -> void:
	if SceneManager.game_controller and not back_to_menu.is_empty():
		SceneManager.game_controller.change_gui_scene(back_to_menu)

func _on_restaurar_padrao_button_down() -> void:
	Settings.reset_settings()

func _on_sair_button_down() -> void:
	get_tree().quit()
