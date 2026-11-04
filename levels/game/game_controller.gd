class_name GameController
extends Node

## Cena raiz do jogo: troca a fase (mundo 2D) e a interface sem trocar a cena principal.
## Acesse de qualquer lugar por `GameController.instance`.

static var instance: GameController

@export var world_2d: Node2D
@export var gui: Control

var current_2d_scene: Node
var current_gui_scene: Node


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	current_gui_scene = $GUI/MainMenu


func change_gui_scene(scene_path: String) -> void:
	var scene := load(scene_path) as PackedScene
	if scene == null:
		push_error("GameController: cena de interface inválida: %s" % scene_path)
		return
	change_gui_scene_instance(scene.instantiate())


func change_gui_scene_instance(scene: Control) -> void:
	if current_gui_scene:
		current_gui_scene.queue_free()
	gui.add_child(scene)
	current_gui_scene = scene


func change_2d_scene(scene: PackedScene) -> void:
	if scene == null:
		push_error("GameController: a cena de mundo não foi definida.")
		return
	if current_2d_scene:
		current_2d_scene.queue_free()
	current_2d_scene = scene.instantiate()
	world_2d.add_child(current_2d_scene)


func delete_current_gui_scene() -> void:
	if current_gui_scene:
		current_gui_scene.queue_free()
		current_gui_scene = null


func delete_current_2d_scene() -> void:
	if current_2d_scene:
		current_2d_scene.queue_free()
		current_2d_scene = null
