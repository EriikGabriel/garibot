extends Node
class_name Phase1BubbleDirection

var layout: Node

func _process(_delta: float) -> void:
	if not is_instance_valid(layout):
		return
	for bubble in layout.bubbles:
		if not is_instance_valid(bubble) or not is_instance_valid(bubble.node_to_point_at):
			continue
		var speaker: Node = bubble.node_to_point_at.get_parent()
		var facing := 1.0
		if speaker is Player:
			facing = float(speaker.orientation)
		elif speaker is Phase1Npc:
			facing = float(speaker.facing_direction)
		bubble.base_direction = Vector2(facing, -1.0).normalized()
		bubble.facing_direction = 1 if facing >= 0.0 else -1
