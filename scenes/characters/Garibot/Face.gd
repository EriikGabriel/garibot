extends Sprite2D

## Controla o quadro da spritesheet de expressões do Garibot.
func _ready() -> void:
	set_face(0)

func set_face(index: int) -> void:
	frame = index
