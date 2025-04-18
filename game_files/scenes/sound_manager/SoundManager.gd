extends Node

signal current_changed(name)

@onready var debug = $debug
@onready var songs_list = $songs
@onready var sfx_list = $sfx
@export var DEBUG_MODE = false

var songs = {}
var sfx = {}
var default_volumes = {}

var current: AudioStreamPlayer
var next: AudioStreamPlayer

var resume_instant = 0
var is_paused = false
var is_switch = false

func _ready():
	randomize()
	if not DEBUG_MODE:
		debug.queue_free()

	for s in songs_list.get_children():
		songs[str(s.name)] = s
		default_volumes[str(s.name)] = s.volume_db
	for s in sfx_list.get_children():
		sfx[str(s.name)] = s

func stop():
	if current:
		current.stop()
	if next:
		next.stop()

func play(stream_name: String, from: float = 0.0):
	is_switch = false
	if songs.has(stream_name):
		if next:
			next.stop()
		next = songs[stream_name]
		if current and next.name == current.name:
			return
		current = next
		emit_signal("current_changed", current.name)
		current.play(from)
	else:
		if current:
			current.stop()
		print_debug("Song '" + stream_name + "' not found")

func play_with_fade_in(stream_name: String, duration: float = 0.8):
	is_switch = false
	if songs.has(stream_name):
		next = songs[stream_name]
		if not current:
			play(stream_name)
			return
		if current and next.name == current.name:
			return
		if not current.stream.loop:
			duration = 0.0
		var tween = create_tween()
		tween.tween_property(current, "volume_db", -80, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		tween.connect("finished", Callable(self, "_on_fade_in_finished"))
	else:
		print_debug("Song '" + stream_name + "' not found")

func _on_fade_in_finished():
	current.stop()
	current.volume_db = default_volumes[current.name]
	current = next
	emit_signal("current_changed", current.name)
	current.play()

func play_with_cross_fade(stream_name: String, duration: float = 0.8):
	if songs.has(stream_name):
		next = songs[stream_name]
		if current and next.name == current.name:
			return
		var tween = create_tween()
		tween.tween_property(current, "volume_db", -20, duration).set_trans(Tween.TRANS_LINEAR)
		tween.tween_callback(Callable(self, "_stop_current_and_set_default"))
		tween.tween_property(next, "volume_db", 0, duration).set_trans(Tween.TRANS_LINEAR)
		next.play()
	else:
		print_debug("Song '" + stream_name + "' not found")

func _stop_current_and_set_default():
	current.stop()
	current.volume_db = default_volumes[current.name]
	current = next
	emit_signal("current_changed", current.name)

func play_fanfare(stream_name: String):
	is_switch = false
	if not current:
		return
	if songs.has(stream_name):
		next = songs[stream_name]
		next.connect("finished", Callable(self, "_on_fanfare_finished"))
		current.stream_paused = true
		next.play()
		emit_signal("current_changed", next.name)
	else:
		print_debug("Fanfare '" + stream_name + "' not found")

func _on_fanfare_finished():
	next.stop()
	current.stream_paused = false
	emit_signal("current_changed", current.name)
	next.disconnect("finished", Callable(self, "_on_fanfare_finished"))

func play_switch(main: String, second: String):
	is_switch = false
	if songs.has(main) and songs.has(second):
		current = songs[second]
		next = songs[main]
		current.volume_db = -50
		current.play()
		next.play()
		is_switch = true
	else:
		print_debug("One of the songs '" + main + "' or '" + second + "' not found")

func switch():
	if is_switch:
		var tween = create_tween()
		if next.volume_db == -50:
			tween.tween_property(current, "volume_db", -50, 1)
			tween.tween_property(next, "volume_db", default_volumes[next.name], 0.1)
			print_debug("switch")
		else:
			tween.tween_property(next, "volume_db", -50, 1)
			tween.tween_property(current, "volume_db", default_volumes[current.name], 0.1)

func play_dual(main: String, second: String):
	is_switch = false
	if songs.has(main) and songs.has(second):
		play(main)
		next = songs[second]
		next.volume_db = -80
	else:
		print_debug("One of the songs '" + main + "' or '" + second + "' not found")

func play_dual_start():
	next.volume_db = 0
	next.play(current.get_playback_position())

func play_dual_stop():
	next.volume_db = -80
	next.stop()

func play_sfx(stream_name: String):
	if stream_name == "":
		sfx["talk_tim"].play()
	elif sfx.has(stream_name):
		sfx[stream_name].play()
	else:
		print_debug("Sfx '" + stream_name + "' not found")

func pause():
	if current:
		is_paused = true
		var tween = create_tween()
		tween.tween_property(current, "volume_db", -80, 0.5)
	if is_switch:
		var tween_next = create_tween()
		tween_next.tween_property(next, "volume_db", -80, 0.5)

func resume():
	if current and is_paused:
		if is_switch:
			current.play(resume_instant)
			next.play(resume_instant)
			create_tween().tween_property(next, "volume_db", default_volumes[next.name], 0.5)
		else:
			current.play(resume_instant)
			create_tween().tween_property(current, "volume_db", default_volumes[current.name], 0.5)
		is_paused = false
	else:
		print_debug("There is no music to resume")
