extends Node2D

@export var next_phase:String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_pass_phase(_body: Node2D) -> void:
	get_tree().change_scene_to_file(next_phase)
	pass
