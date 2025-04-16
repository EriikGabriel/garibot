tool
extends "res://scenes/item/ItemScript.gd"

export(String, "magnet", "bubble", "shock") var blaster

func _ready():
	set_blaster(blaster)


func set_blaster(_blaster):
	blaster = _blaster
	
	match blaster:
		"magnet":
			$Sprite.set_texture(load("res://assets/Images/Blasters/magnet.png"))
			$Node2D/TutorialWindow.set_texts(load("res://assets/Images/Blasters/magnet.png"), 
			"ENGENHOCA MAGNÉTICA", 
			"COM ELA, VOCÊ PODE ANDAR NAS PAREDES E NO TETO!", 
			"APERTE X PARA ATIVAR E DESATIVAR O IMÃ")
		"bubble":
			$Sprite.set_texture(load("res://assets/Images/Blasters/bubble.png"))
			$Node2D/TutorialWindow.set_texts(load("res://assets/Images/Blasters/bubble.png"),
			"ENGENHOCA AQUÁTICA", 
			"COM ELA, VOCÊ PODE FLUTUAR USANDO BOLHAS!", 
			"APERTE E SEGURE X PARA USAR")
		"shock":
			$Sprite.set_texture(load("res://assets/Images/Blasters/hydro.png"))
			$Node2D/TutorialWindow.set_texts(load("res://assets/Images/Blasters/hydro.png"),
			"ENGENHOCA ELÉTRICA", 
			"COM ELA VOCÊ PODE ATIVAR CIRCUITOS DE ELEVADORES!", 
			"APERTE X PARA USAR, SEGURE X PARA LANÇAR MAIS LONGE")

# ---- Item ---------------------------
func _on_ItemBlaster_body_entered(body):
	if body.name == "Player":
		body.call_deferred("change_blaster", blaster)
		$Node2D/TutorialWindow.show()
		$Sprite.visible = false
		
		DJ.play_sfx("blaster_get")
		$CollisionShape2D.set_deferred("disabled", true)


func collect():
	queue_free()


func _on_TutorialWindow_popup_hide():
	collect()
