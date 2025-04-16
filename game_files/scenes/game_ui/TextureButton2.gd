extends TextureButton

export var gallery_node : NodePath

func _on_TextureButton2_pressed():
	get_node(gallery_node).open_gallery()
