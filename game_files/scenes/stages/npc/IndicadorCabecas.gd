extends Control

const X_OFFSET = 54
const Y_OFFSET = 54
export(Texture) var descontente
export(Texture) var contente
export(PackedScene) var cabeca

func setup(qtd):
	for _i in range(qtd):
		var new = cabeca.instance()
		$VBoxContainer/HBoxContainer.add_child(new)
	
	_hide_box_if_empty()

func update_seguidores(seguidores):
	visible = true
	var i = 0
	for child in $VBoxContainer/HBoxContainer.get_children():
		if i < seguidores:
			child.set_texture(contente)
		else:
			child.set_texture(descontente)
		i += 1


func _hide_box_if_empty():
	if $VBoxContainer/HBoxContainer.get_child_count() < 1:
		self.visible = false
