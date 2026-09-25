class_name GameController
extends Node

## Controla as cenas de mundo e interface sem trocar a cena raiz do Godot.
@export var world_2d: Node2D
@export var gui: Control

var current_2d_scene: Node
var current_gui_scene: Node

func _ready() -> void:
	SceneManager.game_controller = self
	current_gui_scene = $GUI/main_menu

## Substitui a interface atual pelo PackedScene localizado em [param scene_path].
func change_gui_scene(scene_path: String, delete: bool = true, keep_running: bool = false) -> void:
	var scene_resource := load(scene_path) as PackedScene
	if scene_resource == null:
		push_error("GameController: cena de interface inválida: %s" % scene_path)
		return

	var scene_instance := scene_resource.instantiate()
	change_gui_scene_instance(scene_instance, delete, keep_running)

func change_gui_scene_instance(scene_instance: Control, delete: bool = true, keep_running: bool = false) -> void:
	if current_gui_scene != null:
		_release_scene(current_gui_scene, gui, delete, keep_running)
	gui.add_child(scene_instance)
	current_gui_scene = scene_instance

## Substitui a fase atual. A cena recebida já é um recurso validado pelo editor.
func change_2d_scene(scene_resource: PackedScene, delete: bool = true, keep_running: bool = false) -> void:
	if scene_resource == null:
		push_error("GameController: a cena de mundo não foi definida.")
		return

	if current_2d_scene != null:
		_release_scene(current_2d_scene, world_2d, delete, keep_running)

	var scene_instance := scene_resource.instantiate()
	world_2d.add_child(scene_instance)
	current_2d_scene = scene_instance

## Libera, oculta ou remove uma cena conforme a política de transição escolhida.
func _release_scene(scene: Node, container: Node, delete: bool, keep_running: bool) -> void:
	if delete:
		scene.queue_free()
	elif keep_running:
		var canvas_item := scene as CanvasItem
		if canvas_item != null:
			canvas_item.visible = false
	else:
		container.remove_child(scene)

func delete_current_gui_scene() -> void:
	if current_gui_scene != null:
		current_gui_scene.queue_free()
		current_gui_scene = null

func delete_current_2d_scene() -> void:
	if current_2d_scene != null:
		current_2d_scene.queue_free()
		current_2d_scene = null

# Compatibilidade temporária com chamadas existentes contendo o nome antigo.
func delete_currrent_gui_scene() -> void:
	delete_current_gui_scene()

func delete_currrent_2d_scene() -> void:
	delete_current_2d_scene()
