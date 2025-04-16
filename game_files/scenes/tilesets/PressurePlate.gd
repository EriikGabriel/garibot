extends Node2D

var plate_target
const DOWN = Vector2(0, 5.73)
const UP = Vector2(0, 0)

signal plate_updated

# Called when the node enters the scene tree for the first time.
func _ready():
	plate_target = $Plate.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Plate.position += 10*delta*(plate_target - $Plate.position)


func _on_Area2D_area_entered(_area):
	plate_target = DOWN
	DJ.play_sfx('pp_down')
	print_debug("DOWN")
	emit_signal("plate_updated", true)


func _on_Area2D_area_exited(_area):
	plate_target = UP
	DJ.play_sfx('pp_up')
	print_debug("UP")
	emit_signal("plate_updated", false)
