class_name RestorableTileMapLayer
extends TileMapLayer

## Camada de tiles com versão suja (textura do TileSet) e limpa (`clean_texture`,
## mesmo layout de atlas), restaurada conforme os REEE coletados.

@export var clean_texture: Texture2D
## 0 = acompanha o progresso; 0.2…1.0 = restaura de uma vez no 1º…5º REEE.
@export_range(0.0, 1.0, 0.05) var restore_step := 0.0


func _ready() -> void:
	material = RestorationProgress.create_material(clean_texture)
	RestorationProgress.connect_to(self, _on_progress)


func _on_progress(shown: float) -> void:
	material.set_shader_parameter(
		"progress", RestorationProgress.restore_factor(shown, restore_step)
	)
