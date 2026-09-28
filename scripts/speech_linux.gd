extends Node
## Síntese isolada: o eSpeak escreve WAV, e o Godot apenas reproduz o áudio.
## Nenhuma chamada ao Speech Dispatcher é feita na thread da interface.
signal voices_ready(available: Array[Dictionary])
signal failed(message: String)
signal started(id: int)

const TIMEOUT_MS := 5000
var executable := ""
var _pid := -1
var _deadline := 0
var _pipe: FileAccess
var _output := PackedByteArray()
var _listing := false
var _wave_path := ""
var _id := 0
var _player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	add_child(_player)
	for directory in OS.get_environment("PATH").split(":"):
		for binary in ["espeak-ng", "espeak"]:
			var path := directory.path_join(binary)
			if directory.is_absolute_path() and FileAccess.file_exists(path):
				executable = path
				return

func load_voices() -> void:
	stop()
	if executable.is_empty():
		failed.emit("Instale o eSpeak NG para leitura sem bloqueios no Linux. Depois, reinicie o jogo.")
		return
	var process := OS.execute_with_pipe(executable, PackedStringArray(["--voices"]), false)
	if process.is_empty():
		failed.emit("Não foi possível iniciar o serviço de voz.")
		return
	_pid = int(process.pid)
	_pipe = process.stdio
	_output.clear()
	_listing = true
	_deadline = Time.get_ticks_msec() + TIMEOUT_MS

func speak(text: String, voice: String, volume: float, rate: float, id: int) -> void:
	stop()
	_id = id
	_player.volume_db = linear_to_db(clampf(volume, 0.0, 1.0))
	_wave_path = ProjectSettings.globalize_path("user://speech_%d_%d.wav" % [OS.get_process_id(), id])
	_pid = OS.create_process(executable, PackedStringArray([
		"-v", voice.trim_prefix("espeak:"), "-s", str(int(175 * rate)),
		"-w", _wave_path, "--", text
	]))
	if _pid <= 0:
		_fail("Não foi possível preparar a leitura em voz alta.")
		return
	_deadline = Time.get_ticks_msec() + TIMEOUT_MS

func _process(_delta: float) -> void:
	if _pid <= 0:
		return
	if _listing:
		# Pipe não bloqueante e leitura limitada por frame.
		_output.append_array(_pipe.get_buffer(8192))
		if _output.size() > 131072:
			_fail("O serviço de voz retornou uma lista inválida.")
			return
	if Time.get_ticks_msec() >= _deadline:
		_fail("A voz demorou mais de 5 segundos. O processo foi cancelado; você pode continuar jogando e usar Testar voz para tentar novamente.")
		return
	if OS.is_process_running(_pid):
		return
	var exit_code := OS.get_process_exit_code(_pid)
	_pid = -1
	if exit_code != 0:
		_fail("O serviço de voz falhou. Use Testar voz nas configurações para tentar novamente.")
		return
	if _listing:
		# Drena somente os bytes restantes, sem esperar novos dados.
		_output.append_array(_pipe.get_buffer(131072))
		_pipe.close()
		_pipe = null
		_listing = false
		voices_ready.emit(parse_voices(_output.get_string_from_utf8()))
	else:
		if not FileAccess.file_exists(_wave_path):
			_fail("O serviço de voz não produziu áudio.")
			return
		_player.stream = AudioStreamWAV.load_from_file(_wave_path)
		_remove_wave()
		if _player.stream == null:
			_fail("Não foi possível ler o áudio da narração.")
			return
		_player.play()
		started.emit(_id)

func parse_voices(output: String) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var whitespace := RegEx.new()
	whitespace.compile("\\s+")
	for line in output.split("\n"):
		var columns := whitespace.sub(line.strip_edges(), " ", true).split(" ", false)
		if columns.size() < 5 or not columns[0].is_valid_int():
			continue
		available.append({"id": "espeak:" + columns[1], "language": columns[1],
			"name": columns[3].replace("_", " ")})
	return available

func stop() -> void:
	if _pid > 0 and OS.is_process_running(_pid):
		OS.kill(_pid)
	_pid = -1
	if _pipe != null:
		_pipe.close()
		_pipe = null
	_listing = false
	if is_instance_valid(_player):
		_player.stop()
		_player.stream = null
	_remove_wave()

func _remove_wave() -> void:
	if not _wave_path.is_empty():
		if FileAccess.file_exists(_wave_path):
			DirAccess.remove_absolute(_wave_path)
		_wave_path = ""

func _fail(message: String) -> void:
	stop()
	failed.emit(message)

func _exit_tree() -> void:
	stop()
