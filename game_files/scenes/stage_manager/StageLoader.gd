extends Node

var err
var path_to_load 
var time_max := 100 # msec
var current_scene
var resource
var is_loading := false

signal resource_loaded

func goto_scene(path: String) -> void:
	if is_loading:
		print("Já há um carregamento em andamento")
		return

	path_to_load = path
	err = ResourceLoader.load_threaded_request(path)
	if err != OK:
		show_error()
		return

	is_loading = true
	set_process(true)

	if current_scene:
		current_scene.queue_free()

	# start your "loading..." animation
	# $AnimationPlayer.play("loading")

func _process(_delta: float) -> void:
	if not is_loading:
		set_process(false)
		return

	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() < t + time_max:

		if err == OK:
			resource = ResourceLoader.load_threaded_get(path_to_load)
			emit_signal("resource_loaded")
			#change_scene()
			is_loading = false
			set_process(false)
			break
		else:
			show_error()
			is_loading = false
			set_process(false)
			break

func show_error() -> void:
	print("Houve um erro ao carregar a cena!")

func change_scene() -> void:
	if resource:
		current_scene = resource.instantiate()
		get_tree().get_root().add_child(current_scene)
	else:
		show_error()
