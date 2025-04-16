extends Node2D

#O timer serve para de-sincronizar todas as animações no começo

func _ready():
	$Timer.start(1)
	pass

func _on_Timer_timeout():
	$GirlBody/Corpo/PersonAnimationPlayer.queue("fear")
	pass
