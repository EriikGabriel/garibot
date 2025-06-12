extends AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if(!is_equal_approx(volume_db,Global.EffectsVolume)):
		_on_changed_volume(Global.EffectsVolume)


func _on_high_mouse_entered() -> void:
	pitch_scale = 1
	play()

func _on_low_mouse_entered() -> void:
	pitch_scale = 0.5
	play()
	
func _on_changed_volume(percent:float):
	volume_db = float(1.04)*percent-80
	Global.EffectsVolume = percent
	
	
