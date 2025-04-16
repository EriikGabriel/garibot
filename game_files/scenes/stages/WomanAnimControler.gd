extends Node2D

#O timer serve para de-sincronizar todas as animações no começo

func _ready():
	$Timer.start(1.25)
	pass

func _on_Timer_timeout():
	$WomanBody/Corpo/PersonAnimationPlayer.play("fear")
	pass
