class_name GameController 
extends Node

@export var world_2d: Node2D
@export var gui: Control

var current_2d_scene
var current_gui_scene

func _ready() -> void:
	SceneManager.game_controller = self
	current_gui_scene = $GUI/main_menu

func change_gui_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
	if current_gui_scene != null:
		if delete:
			current_gui_scene.queue_free() # Remove o nó inteiramente
		elif keep_running:
			current_gui_scene.visible = false # Mantém em memória e executando
		else:
			gui.remove_child(current_gui_scene) # Mantém em memória, mas não executa

	var new = load(new_scene).instantiate()
	gui.add_child(new)
	current_gui_scene = new


func change_2d_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
	if current_2d_scene != null:
		if delete:
			current_2d_scene.queue_free() # Remove o nó inteiramente
		elif keep_running:
			current_2d_scene.visible = false # Mantém em memória e rodando
		else:
			world_2d.remove_child(current_2d_scene) # Mantém em memória, mas não roda

	var new = load(new_scene).instantiate()
	world_2d.add_child(new)
	current_2d_scene = new
	
func delete_currrent_gui_scene() -> void:
	if current_gui_scene != null:
		current_gui_scene.queue_free() 
		current_gui_scene = null

func delete_currrent_2d_scene() -> void:
	if current_2d_scene != null:
		current_2d_scene.queue_free() 
		current_2d_scene = null
