extends Node

const key_shortcut = "roll_attack"
var hold_time = 0
var playing = false
var flag_next_line = false

const base_text_speed = .5
@onready var text_speed = base_text_speed
const MAX_CHAR = 200

var initial_position

@export var dialog = ["Texto 1", "Texto 2"]
@export var corpo_anim_override: NodePath = "Corpo/PersonAnimationPlayer"
@export var anim_player_override: NodePath = "AnimationPlayer"

@onready var balao_texto = $Balao/Texto
@onready var corpo_anim = get_node(corpo_anim_override)
@onready var anim_player = get_node(anim_player_override)

signal finished


func _process(delta):
	fast_forward_input(delta)
	next_line_control(delta)
	skip_dialog_control(delta)


func fast_forward_input(delta):
	if !playing:
		return
	
	if $Balao/Texto.percent_visible < 1:
		$Space.set_visible(false)
		if Input.is_action_pressed(key_shortcut):
			hold_time += delta
		else:
			hold_time = 0
			anim_player.set_speed_scale(1*text_speed)
			$FastForwardIcon.set_visible(false)
			
		if hold_time >= 2*delta:
			anim_player.set_speed_scale(2*text_speed)
			$FastForwardIcon.set_visible(true)
	else:
		$FastForwardIcon.set_visible(false)
		$Space.set_visible(true)


func play(dialog_text):
	var new_dialog = split_text(tr(dialog_text))
	
	if not new_dialog.is_empty():
		self.dialog = new_dialog.duplicate()
	play_next()
	playing = true


func stop():
	playing = false
	$FastForwardIcon.set_visible(false)
	$Space.set_visible(false)
	emit_signal("finished")


func play_next():
	var new_text = dialog.pop_front()
	if len(new_text) != 0:
		text_speed = float(MAX_CHAR)/float(len(new_text))*base_text_speed
	
	balao_texto.set_text(new_text)
	corpo_anim.play("talk")
	anim_player.play("play_line")


func play_default():
	corpo_anim.play("idle")
	anim_player.play("default")
	stop()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "play_line":
		flag_next_line = true
#		if not dialog.empty():
#			play_next()
#		else:
#			play_default()


func next_line_control(_delta) :
	if flag_next_line and Input.is_action_just_pressed("ui_accept"):
		$Balao/Texto.visible = false
		if not dialog.is_empty():
			play_next()
		else:
			play_default()
		flag_next_line = false


func skip_dialog_control(_delta) :
	if Input.is_action_just_pressed("ui_cancel"):
		play_default()

# --- Split text ------------


func split_text(text : String) :
	# split splitted
	var splited_dialog = []
	var dialog_paragraphs = Array(text.split("§"))
	
	# split unsplitted
	for dialog_paragraph in dialog_paragraphs:
		var words = Array(dialog_paragraph.replace(" ","|").split("|"))
		while not words.is_empty():
			var s = ""
			while not words.is_empty() and s.length() + words[0].length() < MAX_CHAR:
				s += words[0]
				words.remove(0)
				if (not words.is_empty() and s.length() + words[0].length() < MAX_CHAR) or string_ends_with_pontuation(s):
					s += " "
				else:
					s += "..."
			splited_dialog.append(s)
			
	#print_debug(splited_dialog)
	return splited_dialog


func string_ends_with_pontuation(s: String):
	return s.ends_with(",") or s.ends_with("!") or s.ends_with("?") or s.ends_with(".")
