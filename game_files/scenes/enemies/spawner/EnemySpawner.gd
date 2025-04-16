extends Position2D


onready var enemy_counter = get_parent().get_node("CanvasLayer/pause_menu/Panel/EnemyCounter")


var is_defeated = false
var enemy
var ENEMY_FILE


func _ready():
	add_to_group("spawners")
	
	if get_child_count() and get_child(1):
		enemy = get_child(1)
		ENEMY_FILE = enemy.get_filename()
	else:
		enemy = null


func _on_enemy_defeated():
	is_defeated = true
	if enemy_counter:
		enemy_counter.update_counter()


func _on_VisibilityNotifier2D_screen_exited():
	if is_defeated and get_child_count() <= 1:
		var virus_enemy = load(ENEMY_FILE).instance()
		
		virus_enemy.set_virus(true)
		
		add_child(virus_enemy)
