extends Panel


@onready var player = get_parent().get_parent().get_child(2)
@onready var itemSpawn = get_parent().get_parent().get_child(7)
var start = false


func _ready():
	self.visible = true
	player.has_control = false
	$Timer.start()
	pass


func _process(_delta):
	if start:
		if Input.is_action_just_pressed("ui_blaster"):
			itemSpawn.get_child(0).start()
			player.has_control = true
			self.visible = false
			self.set_process(false)
	else:
		if Input.is_action_just_pressed("ui_blaster"):
			self._on_Timer_timeout()


func _on_Timer_timeout():
	$VBoxContainer/Label5.set_text("Aperte X para Continuar")
	start = true
