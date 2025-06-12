extends TextureButton

var start_scale :Vector2 = scale
var check_cursor :bool = true
@export var max_scale :float = 0.05 #max of 10% bigger
@export var scale_rate :float = 1 #how much scale changes per sec
@export var next_scene :String = ""
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position.x = (get_viewport_rect().size.x-texture_normal.get_width()*scale.x)/2
	connect("button_down", Callable(self, "on_button_down"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(is_hovered()):
		scale = scale+Vector2.ONE*delta*scale_rate
		scale = scale.min(start_scale*(1+max_scale))
	else:
		scale = scale-Vector2.ONE*delta*scale_rate*2
		scale = scale.max(start_scale)
	position.x = (get_viewport_rect().size.x-texture_normal.get_width()*scale.x)/2
	
func on_button_down():
	if(name == "Sair"):
		get_tree().quit()
	get_tree().change_scene_to_file(Global.trim_path(next_scene))
