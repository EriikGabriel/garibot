extends Node2D

export var velocidade = 5
export var distancia = 1000
export var direcaox = 0
export var direcaoy = 0
var origin_position = 0
var diffpos = 0

var body_array = []

func _ready():
	origin_position = self.position


func _physics_process(delta):
	# Calculate movement
	var x = int(self.position.x - origin_position.x) 
	var y = int(self.position.y - origin_position.y)
	diffpos = sqrt(pow(x,2) + pow(y,2))
	if(diffpos >= (distancia)) :
		origin_position = self.position
		direcaox = direcaox * -1
		direcaoy = direcaoy * -1
		
	# Execute movement
	self.position.x = self.position.x + (velocidade*direcaox)
	self.position.y = self.position.y + (velocidade*direcaoy) 
	
	# Move bodies
	for body in body_array:
		body.position.x = body.position.x + (velocidade*direcaox)
		body.position.y = body.position.y + (velocidade*direcaoy) 
	#print((int(self.position.x - origin_position.x)^2 + int(self.position.y - origin_position.y)^2))
	#print(x*x)
	
	pass # Replace with function body.



func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		print("entered " + body.get_name())
		body_array.append(body)


func _on_Area2D_body_exited(body):
	print("exited " + body.get_name())
	body_array.erase(body)
