extends Control

@export var next_phase : String = " "

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_jogar_button_down() -> void:
	get_tree().change_scene_to_file(next_phase)
	pass # Replace with function body.


func _on_sair_button_down() -> void:
	get_tree().quit()
	pass # Replace with function body.
