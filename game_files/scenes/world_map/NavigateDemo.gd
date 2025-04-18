extends Node2D

@onready var nav : Navigation2D = $Navigation2D

var path : PackedVector2Array
var goal : Vector2
@onready var current_stage_number = Global_variable.last_stage_number
@export var speed := 200
var move = false

@export var stage_name : NodePath
@onready var stage_name_node : Label = get_node(stage_name)

@export var stage_name_box : NodePath
@onready var stage_name_box_node : MarginContainer = get_node(stage_name_box)

#Vetor de coordenadas das fases
const stages = [ 
				Vector2(26,20),
				Vector2(34,20),
				Vector2(39,12),
				Vector2(39,2)
				]

const stage_names = ["Tutorial", "Fase 1", "Fase 2", "Fase 3"]

func _ready():
	if current_stage_number == null:
		current_stage_number = 0
	print("current",current_stage_number)
	$Player.position = $Navigation2D/fases.map_to_local(stages[current_stage_number]) + Vector2(0,20)
	stage_name_node.text = stage_names[current_stage_number]

func _input(event):
	if event.is_action_pressed("ui_right") and move == false :
		if current_stage_number+1 < stages.size():
			goal = stages[current_stage_number+1]
			path = nav.get_simple_path($Player.position, $Navigation2D/TileMap.map_to_world(goal + (Vector2(1,1)), false))
			$Line2D.points = PackedVector2Array(path)
			$Line2D.show()
			current_stage_number += 1
			$Player/PlayButtonMap.stage = current_stage_number
		move = true
	if event.is_action_pressed("ui_left") and event.pressed and move == false:
		if current_stage_number-1 >= 0:
			goal = stages[current_stage_number-1]
			path = nav.get_simple_path($Player.position, $Navigation2D/TileMap.map_to_world(goal + (Vector2(1,1)), false))
			$Line2D.points = PackedVector2Array(path)
			$Line2D.show()
			current_stage_number -= 1
			$Player/PlayButtonMap.stage = current_stage_number
			move = true
	
	stage_name_node.text = stage_names[current_stage_number]

func _process(delta: float) -> void:
	if !path:
		$Line2D.hide()
		$Player/PlayButtonMap.visible = true
		$Player/Left.visible = current_stage_number > 0
		$Player/Right.visible = current_stage_number < (stages.size() -1)
		stage_name_box_node.visible = true
		move = false
		return
	if path.size() > 0:
		$Player/PlayButtonMap.visible = false
		var d: float = $Player.position.distance_to(path[0])
		if d > 10:
			$Player.position = $Player.position.lerp(path[0], (speed * delta)/d)
		else:
			path.remove(0)
		$Player/Left.visible = false
		$Player/Right.visible = false
		stage_name_box_node.visible = false
