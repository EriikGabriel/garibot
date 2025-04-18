extends Node2D

@export var value_bar : NodePath
@export var back_texture : Texture2D
@export var dark_sky : bool = false

@onready var value_bar_node : TextureProgressBar = get_node(value_bar)
@onready var anim_tree = $AnimationTree
@onready var sky_modulate = $ParallaxBackground/ParallaxLayer2/CanvasModulate

var max_value

func _ready():
	sky_modulate.set_visible(dark_sky)
	_set_anim_params(0.0)
	var _return = value_bar_node.connect("value_changed", Callable(self, "_on_Bar_value_changed"))
	_return = value_bar_node.connect("changed", Callable(self, "_on_Bar_changed"))
	$ParallaxBackground/ParallaxLayer/casas.set_texture(back_texture)

func _on_Bar_changed():
	max_value = value_bar_node.max_value

func _on_Bar_value_changed(value : float):
	_set_anim_params(value/max_value)

func _set_anim_params(f : float):
	f = min(1,f*1.2)
	anim_tree["parameters/blend_color/blend_amount"] = f
	anim_tree["parameters/blend_trash/blend_amount"] = (f * 2) - 1
	anim_tree["parameters/blend_tree/blend_amount"] = f
	anim_tree["parameters/blend_tree/blend_amount"] = f
