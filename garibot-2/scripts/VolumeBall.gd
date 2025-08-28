extends Area2D
var follow :bool = false
@export_enum("music", "effects") var vol_type = "effects"#in percentage
signal Changed(percent:float)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var initial_volume = 50
	match vol_type:
		"music":
			initial_volume = Global.MusicVolume
		"effects":
			initial_volume = Global.EffectsVolume
	set_progress(initial_volume)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if follow:
		if Input.is_action_pressed("Drag"):
			if(get_viewport() == null): print("NULL")
			$Ball.global_position.x = clamp(get_viewport().get_mouse_position().x, -$Bar.texture.get_width()/2+$Bar.global_position.x, $Bar.texture.get_width()/2+$Bar.global_position.x)
		if Input.is_action_just_released("Drag"):
			emit_signal("Changed", get_progress())
func _on_mouse_entered() -> void:
	follow = true


func _on_mouse_exited() -> void:
	follow = false
	emit_signal("Changed", get_progress())
	
func get_progress() -> float:
	return 100*$Ball.position.x/$Bar.texture.get_width() #returns percentage
	
func set_progress(val : float) -> void:
	$Ball.position.x = clamp($Bar.texture.get_width()*val/100, 0, $Bar.texture.get_width()/2+$Bar.global_position.x)
