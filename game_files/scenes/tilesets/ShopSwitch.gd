extends Node

@export var up_sprite: Texture2D
@export var down_sprite: Texture2D
@export var up = false

signal changed_direction

func _ready():
	up = !up
	set_direction()

func set_direction():
	up = !up

	if up:
		$Sprite2D.texture = up_sprite
	else:
		$Sprite2D.texture = down_sprite

func _on_Botao_area_entered(area):
	if area.collision_layer == 2:
		DJ.play_sfx("pp_up")
		set_direction()
		emit_signal("changed_direction")

