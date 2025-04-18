extends Node

signal current_changed(name)

@onready var debug = $debug
@onready var songs_list = $songs
@onready var sfx_list = $sfx
@export var DEBUG_MODE = false

# Songs and sound effects dictionary is populated at _ready()
var songs = { }
var sfx = { }
var default_volumes = { }

# Current stream playing
var current: AudioStreamPlayer

# Auxiliary stream to play, used for fade effects and vertical mixing
var next: AudioStreamPlayer


var resume_instant = 0
var dual_main_instant = 0
var dual_second_instant = 0
var is_paused = false
var is_switch = false


# Loads all audio streams available at songs and sfx nodes
func _ready():
	randomize()
	
	if not DEBUG_MODE:
		debug.queue_free()
		
	for s in songs_list.get_children():
		songs[str(s.name)] = s
		default_volumes[str(s.name)] = s.get_volume_db()
	for s in sfx_list.get_children():
		sfx[str(s.name)] = s


# Stops playing audio streams
func stop():
	if current: current.stop()
	if next: next.stop()


# Play stream by the name and where to begin playing by seconds 
func play(name: String, from: float = 0.0):
	$TweenFadeIn.stop_all()
	is_switch = false
	
	if songs.has(name):
		if next: next.stop()
		next = songs[name]
		
		# Do not start the same song again
		if current && next.name == current.name: return
		
		current = next
		
		emit_signal("current_changed", current.name)
		current.play(from)
	else:
		current.stop()
		print_debug("Song \'" + name + "\' not found")


# Fade-out current stream and set next stream to play
func play_with_fade_in(name: String, duration: float = 0.8):
	$TweenFadeIn.stop_all()
	is_switch = false

	if songs.has(name):
		# 10% chance of dameDaNe
		#if name == 'stage_1' and randi() % 10 == 0:
		#	name = 'dameDaNe'
			
		next = songs[name]
		
		if not current: play(name)
		
		# Do not start the same stream again
		if current && next.name == current.name: return
		
		# if current stream is not a loop, start next right away
		if not current.stream.loop:
			duration = 0.0
			
		$TweenFadeIn.interpolate_method(current, "set_volume_db",
			current.get_volume_db(), -80, duration, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$TweenFadeIn.start()
	else:
		print_debug("Song \'" + name + "\' not found")


func _on_TweenFadeIn_tween_completed(object, _key):
	object.stop()
	object.set_volume_db(default_volumes[object.name])
	
	current = next
	emit_signal("current_changed", current.name)
	current.play()


# Fade-out current stream and fade-in next stream
func play_with_cross_fade(name: String, duration: float = 0.0):
	if songs[name]:
		next = songs[name]
		
		# Do not start the same stream again
		if current && next.name == current.name: return
		
		$TweenCrossCurr.interpolate_method(current, "set_volume_db",
			current.get_volume_db(), -20, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, duration)
		$TweenCrossNext.interpolate_method(next, "set_volume_db",
			-20, 0, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$TweenCrossCurr.start()
		$TweenCrossNext.start()
		
		next.play()
	else:
		print_debug("Song \'" + name + "\' not found")


func _on_TweenCrossCurr_tween_completed(_object, _key):
	current.stop()
	current.set_volume_db(default_volumes[current.name])
	
	current = next
	emit_signal("current_changed", current.name)


# Pause current stream to play new stream
func play_fanfare(name: String):
	$TweenFadeIn.stop_all()
	is_switch = false
	
	if !current:
		return
	if songs[name]:
		next = songs[name]
		
		if next.connect("finished", Callable(self, "_on_fanfare_finished")):
			return
		
		current.stream_paused = true
		next.play()
		emit_signal("current_changed", next.name)
	else:
		print_debug("Fanfare \'" + name + "\' not found")


func _on_fanfare_finished():
	next.stop()
	current.stream_paused = false
	emit_signal("current_changed", current.name)
	next.disconnect("finished", Callable(self, "_on_fanfare_finished"))


# Play main stream, prepare second stream to switch at the same time
func play_switch(main: String, second: String):
	$TweenSwitchCurr.stop_all()
	$TweenSwitchNext.stop_all()
	is_switch = false
	
	if songs.has(main) and songs.has(second):
		current = songs[second]
		next = songs[main]
		current.set_volume_db(-50)
		current.play()
		next.play()
		is_switch = true
	else:
		print_debug("One of the songs \'" + main + "\' and \'" + second + "\' not found")


func switch():
	if is_switch:
		if next.get_volume_db() == -50:
			$TweenSwitchCurr.interpolate_method(current, "set_volume_db",
					current.get_volume_db(), -50, 1, 
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TweenSwitchNext.interpolate_method(next, "set_volume_db",
					-50, default_volumes[next.name], 0.1, 
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TweenSwitchCurr.start()
			$TweenSwitchNext.start()
			print_debug('switch')
		else:
			$TweenSwitchCurr.interpolate_method(next, "set_volume_db",
					next.get_volume_db(), -50, 1,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TweenSwitchNext.interpolate_method(current, "set_volume_db",
					-50, default_volumes[current.name], 0.1, 
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TweenSwitchCurr.start()
			$TweenSwitchNext.start()


# Play main stream, prepare second stream to play at the same time
func play_dual(main: String, second: String):
	is_switch = false
	
	if songs.has(main) and songs.has(second):
		self.play(main)
		next = songs[second]
		next.set_volume_db(-80)
	else:
		print_debug("One of the songs \'" + main + "\' and \'" + second + "\' not found")


# Play setted second stream
func play_dual_start():
	next.set_volume_db(0)
	next.play(current.get_playback_position())


# Stop setted second stream
func play_dual_stop():
	next.set_volume_db(-80)
	next.stop()


func play_sfx(name: String):
	if name == '':
		sfx["talk_tim"].play()
	
	if sfx.has(name):
		sfx[name].play()
	else:
		print_debug("Sfx \'" + name + "\' not found")
		
		
func pause():
	if current:
		is_paused = true
		$TweenFadeInPause.interpolate_method(current, "set_volume_db",
			current.get_volume_db(), -80, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$TweenFadeInPause.start()
	
	if is_switch:
		is_paused = true
		$TweenFadeInPause.interpolate_method(next, "set_volume_db",
			next.get_volume_db(), -80, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$TweenFadeInPause.start()
		
		
func resume():
	if current and is_paused:
		if is_switch:
			current.play(resume_instant)
			next.play(resume_instant)
			$TweenFadeInPause.interpolate_method(next, "set_volume_db",
				next.get_volume_db(), default_volumes[next.name], 0.5,
				Tween.TRANS_LINEAR, Tween.EASE_IN)
			$TweenFadeInPause.start()
		else: 
			current.play(resume_instant)
			$TweenFadeInPause.interpolate_method(current, "set_volume_db",
				current.get_volume_db(), default_volumes[current.name], 0.5,
				Tween.TRANS_LINEAR, Tween.EASE_IN)
			$TweenFadeInPause.start()
		is_paused = false
	else:
		print_debug("There is no music resume")


func _on_TweenFadeInPause_tween_completed(_object, _key):
	if is_paused:
		if is_switch:
			resume_instant = next.get_playback_position() - 0.5
			current.stop()
			next.stop()
		else:
			resume_instant = current.get_playback_position() - 0.5
			current.stop()
