extends Node2D

export var animation_tree: NodePath
onready var animation_tree_node: AnimationTree = get_node(animation_tree)

export var test: bool

func _on_DialogBoss_dialog_finished(node_name):
	animation_tree_node["parameters/conditions/to_scene_3_2"] = test


func _on_DialogGaridog_dialog_finished(node_name):
	animation_tree_node["parameters/conditions/to_scene_3_3"] = true
