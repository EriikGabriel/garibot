extends Area2D

var _float_direction = 1
var _float_amount

func _ready():
	if not Engine.editor_hint:
		init_float()


func init_float():
	_float_amount = 8 #$Sprite.texture.get_size().y
	position.y -= _float_amount
	_float_y(_float_direction*_float_amount)


# ------- Animation ----------------
func _float_y(amount):
	$Tween.interpolate_property(self, "position", self.position, self.position+Vector2(0, amount), 1,
	Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()


# warning-ignore:unused_class_variable
func _on_Tween_tween_completed(_object, _key):
	_float_direction *= -1
	_float_y(_float_direction*_float_amount)
