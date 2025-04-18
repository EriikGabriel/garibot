extends Node2D

signal play_end
signal created_ui

@export var minigame: PackedScene
@export var blaster = "shock"
var player

func _ready():
	$"3DPrinter/Polygon2D2/ItemBlaster".set_blaster(blaster)


func _on_Area2D_body_entered(body):
	if body.name == "Player":
		player = body
		player.set_in_cutscene(true)
		var item_list = player.get_collected_items()
		player.get_node("FollowItems").hide();
		player.set_camera_offset(Vector2(-100,-80))
		player.set_camera_zoom(Vector2(0.9,0.9))
		player.change_orientation(-1)
		
		# Open and setup window
		var new = minigame.instantiate()
		new.connect("minigame_done", Callable(self, "start_animation"))
		new.setup_items(item_list)
		emit_signal("created_ui", new)
		#get_parent().find_node("GameUI", true, true).add_child(new)


func start_animation():
	DJ.pause()
	$Controller.queue("print_scene");
	$RecyclingAnimation.play("reciclando_on")


func ending_animation():
	DJ.resume()
	player.set_in_cutscene(false)
	player.set_camera_offset(Vector2(0,0))
	player.set_camera_zoom(Vector2(1,1))
	$"3DPrinter/Polygon2D2/ItemBlaster".monitorable = true
	$"3DPrinter/Polygon2D2/ItemBlaster".monitoring = true
	emit_signal("play_end")
	$RecyclingAnimation.play("reciclando_off")

