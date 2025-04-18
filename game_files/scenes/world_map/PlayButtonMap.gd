extends TextureButton

@onready var stage = Global_variable.last_stage_number

const key_shortcut = "ui_accept"

func _ready():
	if stage == null:
		stage = 0

func _unhandled_input(_event):
	if Input.is_action_just_released(key_shortcut) and self.is_visible_in_tree():
		_pressed()

func _pressed():
	if stage <= 0:
		StageManager.change_stage("tutorial")
	else:
		print("stage_" + str(stage))
		StageManager.change_stage("stage_" + str(stage))
	self.get_parent().get_parent().visible = false
