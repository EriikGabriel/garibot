@tool
extends Sprite2D
class_name Phase1RestorableSprite

## Sprite do plano do jogo (casa, árvore) com versão suja (`texture`) e limpa.
## É restaurado de uma vez quando o progresso de REEE alcança `restore_step`,
## acompanhando a transição animada do Phase1Background.
const BLEND_SHADER := preload("res://levels/phase1/background/pollution_blend.gdshader")

@export var clean_texture: Texture2D:
	set(value):
		clean_texture = value
		if _material:
			_material.set_shader_parameter("clean_texture", value)
## Degrau de restauração: 0.2 = 1º REEE ... 1.0 = 5º REEE (0 = gradual).
@export_range(0.0, 1.0, 0.05) var restore_step := 0.2

var _material: ShaderMaterial
var _background: Phase1Background

func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = BLEND_SHADER
	_material.set_shader_parameter("clean_texture", clean_texture)
	_material.set_shader_parameter("use_mask", false)
	material = _material

func _process(_delta: float) -> void:
	if not is_instance_valid(_background):
		_background = get_tree().get_first_node_in_group("phase1_background") as Phase1Background
		if _background == null:
			return
	var restored := Phase1Background.restore_factor(_background.shown_progress(), restore_step)
	_material.set_shader_parameter("progress", restored)
