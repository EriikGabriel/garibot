extends Node2D

func _ready():
	$sfx.play(0)

func _on_sfx_finished():
	.call_deferred("queue_free")
