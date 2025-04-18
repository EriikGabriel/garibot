extends Node2D

var lower_target
var finished = false
var open = false

@export var start_open = false

const LOWER_OPEN = Vector2(0, 100)
const LOWER_CLOSED = Vector2(0, 0)

func _ready():
	lower_target = $Lower.position
	if start_open:
		open()

func _process(delta):
	if !finished:
		var difference = lower_target - $Lower.position
		if abs(difference.y) > 0.05 || abs(difference.x) > 0.05:
			$Lower.position += 2*delta*(lower_target - $Lower.position)
		else:
			finished = true
			if open:
				close()


func open():
	lower_target = LOWER_OPEN
	finished = false
	open = true
	
	DJ.play_sfx('hammer_open')


func close():
	lower_target = LOWER_CLOSED
	finished = false
	open = false
	
	DJ.play_sfx('hammer_close')


func _on_PressurePlate_plate_updated(pressed):
	if pressed:
		open()
	else:
		close()


func _on_Lower_area_entered(area):
	if !finished:
		area.tag()
