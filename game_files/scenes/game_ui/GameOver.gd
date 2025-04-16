extends Control

onready var animPlayer = $AnimationPlayer

func _on_game_over_visibility_changed():
	Global_variable.mobile_control_node.hide_pause_button()
	if self.is_visible_in_tree():
		self.get_tree().paused = true
		$AnimationPlayer.play("GameOver")
		$Timer.start()
		DJ.play_fanfare("lose_fanfare")



func _on_Timer_timeout():
	$Panel/RetryButton.disabled = false
	$Panel/MainMenuButton.disabled = false
	#print_debug($Panel/RetryButton.disabled, $Panel/MainMenuButton.disabled)


func _on_RetryButton_pressed():
	if $Timer.is_stopped():
		print_debug($Timer)
		self.get_tree().paused = false
		StageManager.reset_stage()


func _on_MainMenuButton_pressed():
	if $Timer.is_stopped():
		self.get_tree().paused = false
		StageManager.change_stage("world_map")
		StageManager.set_checkpointed(false)


