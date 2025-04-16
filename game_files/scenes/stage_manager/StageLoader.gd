extends Node

var loader
var wait_frames
var time_max = 100 # msec
var current_scene
var resource

signal resource_loaded

func goto_scene(path): # game requests to switch to this scene
	loader = ResourceLoader.load_interactive(path)
	if loader == null: # check for errors
		show_error()
		return
	set_process(true)
	
	if current_scene: current_scene.queue_free() # get rid of the old scene

	# start your "loading..." animation
	#get_node("animation").play("loading")

	wait_frames = 0

func _process(_time):
	if loader == null:
		# no need to process anymore
		set_process(false)
		return

	if wait_frames > 0: # wait for frames to let the "loading" animation to show up
		wait_frames -= 1
		return

	var t = OS.get_ticks_msec()
	while OS.get_ticks_msec() < t + time_max: # use "time_max" to control how much time we block this thread

		# poll your loader
		var err = loader.poll()

		if err == ERR_FILE_EOF: # load finished
			resource = loader.get_resource()
			emit_signal("resource_loaded")
			loader = null
			break
		elif err == OK:
			update_progress()
		else: # error during loading
			show_error()
			loader = null
			break

func show_error():
	print("Houve um erro ao carregar a cena!")

func update_progress():
	var _progress = float(loader.get_stage()) / loader.get_stage_count()
	# update your progress bar?
	#get_node("progress").set_progress(progress)

	# or update a progress animation?
	#var length = get_node("animation").get_current_animation_length()

