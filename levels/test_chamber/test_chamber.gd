extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Play the intro cutscene once the level starts.
	var cutscene: CutscenePlayer = get_node_or_null("CutscenePlayer")
	if cutscene != null:
		cutscene.run()
