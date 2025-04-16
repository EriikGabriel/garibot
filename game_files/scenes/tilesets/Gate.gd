extends Node2D

var upper_target
var lower_target
var finished = false

export var start_open = false
export var last_gate = false

const UPPER_OPEN = Vector2(0, -175)
const UPPER_CLOSED = Vector2(0, 0)
const LOWER_OPEN = Vector2(0, 175)
const LOWER_CLOSED = Vector2(0, 0)

export var level_complete : NodePath
onready var level_complete_node = get_node(level_complete)

func _ready():
	upper_target = $Upper.position
	lower_target = $Lower.position
	if start_open:
		open()

func _physics_process(delta):
	if !finished:
		if abs((upper_target - $Upper.position).y) > 0.05 || abs((upper_target - $Upper.position).x) > 0.05:
			$Upper.position += 2*delta*(upper_target - $Upper.position)
			$Lower.position += 2*delta*(lower_target - $Lower.position)
		else:
			finished = true


func open():
	upper_target = UPPER_OPEN
	lower_target = LOWER_OPEN
	finished = false
	
	DJ.play_sfx('gate_open')


func close():
	upper_target = UPPER_CLOSED
	lower_target = LOWER_CLOSED
	finished = false
	
	DJ.play_sfx('gate_close')


func _on_PressurePlate_plate_updated(pressed):
	if pressed:
		if !last_gate:
			open()
		else:
			play_end_animation()


func play_end_animation():
	StageManager.change_stage('end_animation', true)

func _on_CloseUpperGate_area_entered(_area):
	close()


func _on_TagItems_area_entered(_area):
	open()


func _on_OpenGate_area_entered(_area):
	open()


func _on_Dialog_finished():
	open()
