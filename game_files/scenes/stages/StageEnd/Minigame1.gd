extends Node2D

const LEFT = 5
const RIGHT = 400
const RIGHT2 = 700
const SPEED = 100

var move_garra = 0
var acquired = 0

var item_body

var right_item = null
var right_item_sprite = null
var right_item_name = null

var timer = 0
export(PackedScene) var usina_item


func _ready():
	var right_index = randi() % 5
	right_item = $UsinaItems.get_child(right_index)
	right_item.set_correct(true)


func _process(delta):
	# Regenerar
	if acquired == 3:
		timer += delta
		if timer > 8:
			timer = 0
			var _new = usina_item.instance()
			add_child(_new)
			_new.init(Vector2(0, 100), Vector2(800, 0))
			_new.set_sprite(right_item_sprite)
			_new.set_texture_item(right_item_name)
			_new.name_item = right_item_name
	
	# Após subir a garra com um objeto
	elif acquired == 2:
		# Mover para a direita
		if $Garra.position.x < RIGHT2:
			$Garra.position.x += delta*SPEED
		
		# Soltar a garra e desativar
		else:
			$Garra.play("open")
			item_body.set_center(null)
			$Portao.open()
			acquired = 3
		return
	
	# Movimento padrão
	if LEFT < $Garra.position.x and move_garra == -1:
		$Garra.position.x -= delta*SPEED
	elif $Garra.position.x < RIGHT and move_garra == 1:
		$Garra.position.x += delta*SPEED


func set_correct_sprite(sprite,name_item):
	print("teste")
	right_item_sprite = sprite
	right_item_name = name_item
	if right_item != null and right_item.has_method("set_sprite"):
		right_item.set_sprite(sprite)
		right_item.set_texture_item(name_item)


func _on_GarraArea_body_entered(body):
	if body != right_item:
		return
	
	item_body = body
	body.set_center($Garra/Main/GarraArea)
	acquired = 1


# Começar a mover para a direita
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "close" and acquired == 1:
		acquired = 2


func move_left(pressed):
	if !acquired:
		move_garra = -int(pressed)


func move_right(pressed):
	if !acquired:
		move_garra = int(pressed)


func _on_Left_plate_updated(pressed):
	move_left(pressed)


func _on_Right_plate_updated(pressed):
	move_right(pressed)


func _on_Down_plate_updated(pressed):
	if !acquired and pressed:
		$Garra.play("close")
