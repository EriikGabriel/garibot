class_name RestorableSprite
extends Sprite2D

## Sprite com versão suja (`texture`) e limpa, restaurado conforme os REEE coletados.

@export var clean_texture: Texture2D
## Opcional: define um degrau por pixel (ver restoration_blend.gdshader).
@export var progress_mask: Texture2D
## 0 = acompanha o progresso; 0.2…1.0 = restaura de uma vez no 1º…5º REEE.
@export_range(0.0, 1.0, 0.05) var restore_step := 0.2


func _ready() -> void:
	material = RestorationProgress.create_material(clean_texture, progress_mask)
	RestorationProgress.connect_to(self, _on_progress)


func _on_progress(shown: float) -> void:
	material.set_shader_parameter(
		"progress", RestorationProgress.restore_factor(shown, restore_step)
	)
