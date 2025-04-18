extends CenterContainer

@onready var mobile_node = $VBox/TextureRect2 

func _ready():
	mobile_node.visible = !Global_variable.mobile_control_flag
