extends Node
## Narração interna via TTS do sistema. Não depende de um leitor externo.

signal status_changed(message: String)
signal voices_changed

const SLOW_CALL_MS := 1500
const START_TIMEOUT_MS := 5000
const SESSION_MARKER := "user://speech_session_pending"
var _suspended := false
var _loading := false
var _session_marked := false
var _pending_speech: Dictionary = {}
var _utterance_id := 0
var _start_deadline := 0
var _notice: PanelContainer
var _notice_label: Label
var _notice_deadline := 0
const FOCUS_DELAY_MS := 120
var _scheduled: Dictionary = {}
var _speak_at := 0
var _linux: Node

var voices: Array[Dictionary] = []
var voice_id := ""
var status_text := "":
	set(value):
		if status_text != value:
			status_text = value
			status_changed.emit(value)
var voices_revision := 0
var _voices_loaded := false
var _channel := ""
var _markup := RegEx.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_notice()
	if OS.get_name() == "Linux":
		_linux = preload("res://scripts/speech_linux.gd").new()
		add_child(_linux)
		_linux.voices_ready.connect(_finish_loading_voices)
		_linux.failed.connect(_on_linux_failure)
		_linux.started.connect(_on_utterance_response)
	elif FileAccess.file_exists(SESSION_MARKER):
		_suspend("A sessão anterior de voz foi interrompida. A leitura está suspensa por segurança. Use Testar voz nas configurações para tentar novamente.")
	_markup.compile("\\[[^\\]]*\\]")
	Settings.setting_changed.connect(_on_setting_changed)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	get_tree().node_added.connect(_on_node_added)
	_hook_tree(get_tree().root)
	_setup_dialogic.call_deferred()
	if enabled():
		speak("Leitura em voz alta ativada. Use Tab para navegar pelos menus.")

func enabled() -> bool:
	return bool(Settings.get_setting("screen_reader", false))

func refresh_voices() -> void:
	if _suspended or _loading:
		return
	# Inclusive a ausência de vozes fica em cache: consultar o serviço do
	# sistema a cada mudança de foco pode bloquear a interface.
	if not _voices_loaded:
		_loading = true
		status_text = "Consultando vozes do sistema..."
		_load_voices.call_deferred()
		return
	voice_id = ""
	if voices.is_empty():
		status_text = "Nenhuma voz disponível. Instale ou habilite uma voz de português brasileiro (pt-BR) no sistema. No Linux, verifique também o Speech Dispatcher. Depois, use Testar voz."
		return
	var selected := select_voice(voices, str(Settings.get_setting("speech_voice", "")))
	if selected.is_empty():
		status_text = "A voz padrão é Português (Brasil), mas nenhuma voz pt-BR está instalada. Instale uma voz brasileira ou escolha outro idioma."
		return
	voice_id = str(selected["id"])
	status_text = "Voz atual: %s (%s)." % [selected["name"], selected["language"]]

func _load_voices() -> void:
	# Dá à interface a oportunidade de desenhar o feedback antes da chamada nativa.
	await get_tree().process_frame
	await get_tree().process_frame
	if _suspended:
		_loading = false
		return
	if _linux != null:
		_linux.load_voices()
		return
	voices.clear()
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		var result: Variant = _guard_native(DisplayServer.tts_get_voices)
		if result is Array and not _suspended:
			voices.assign(result)
		if not _suspended:
			DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, _on_utterance_response)
			DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _on_utterance_response)
			DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, _on_utterance_response)
	_finish_loading_voices(voices)

func _finish_loading_voices(available: Array[Dictionary]) -> void:
	voices = available
	_loading = false
	_voices_loaded = true
	voices_revision += 1
	refresh_voices()
	voices_changed.emit()
	var pending := _pending_speech
	_pending_speech = {}
	if not pending.is_empty() and not _suspended:
		speak(pending.text, pending.channel, pending.preview)

func _on_linux_failure(message: String) -> void:
	_loading = false
	_suspend(message)

func _guard_native(operation: Callable) -> Variant:
	if _suspended:
		return null
	if not _session_marked:
		var marker := FileAccess.open(SESSION_MARKER, FileAccess.WRITE)
		if marker != null:
			marker.store_string("Leitura em voz alta em uso")
			marker.close()
			_session_marked = true
	var started := Time.get_ticks_msec()
	var result: Variant = operation.call()
	if Time.get_ticks_msec() - started >= SLOW_CALL_MS:
		_suspend("O serviço de voz demorou demais. A leitura foi suspensa para evitar novas travadas. Você pode continuar jogando e tentar novamente em Testar voz.")
	return result

func _suspend(message: String) -> void:
	_suspended = true
	_loading = false
	_start_deadline = 0
	_pending_speech = {}
	_scheduled = {}
	if _linux != null:
		_linux.stop()
	status_text = message
	_notice_label.text = message
	_notice.show()
	_notice_deadline = Time.get_ticks_msec() + 12000
	# Não chamamos tts_stop aqui: um serviço travado pode bloquear também ao parar.

func _on_utterance_response(id: int) -> void:
	if id == _utterance_id:
		_start_deadline = 0

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if not _scheduled.is_empty() and now >= _speak_at:
		var request := _scheduled
		_scheduled = {}
		_speak_now(request.text, request.channel, request.preview)
	if _start_deadline > 0 and now >= _start_deadline:
		_suspend("A voz não respondeu em 5 segundos. A leitura está suspensa; o jogo continua disponível. Use Testar voz para tentar novamente.")
	if _notice_deadline > 0 and now >= _notice_deadline:
		_notice.hide()
		_notice_deadline = 0

func _create_notice() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 300
	add_child(layer)
	_notice = PanelContainer.new()
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_notice)
	_notice.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_notice.offset_left = 24
	_notice.offset_right = -24
	_notice.offset_top = -150
	_notice.offset_bottom = -24
	_notice_label = Label.new()
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice.add_child(_notice_label)
	_notice.hide()

func _exit_tree() -> void:
	if _session_marked and not _suspended:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_MARKER))

func select_voice(available: Array[Dictionary], preferred: String) -> Dictionary:
	# Uma escolha explícita é respeitada; o modo automático usa somente pt-BR.
	for voice in available:
		if not preferred.is_empty() and str(voice["id"]) == preferred:
			return voice
	for voice in available:
		var language := str(voice.get("language", "")).replace("_", "-").to_lower()
		if language == "pt-br" or language.begins_with("pt-br-"):
			return voice
	return {}

func plain_text(value: String) -> String:
	return _markup.sub(value, "", true).replace("\n", ". ").strip_edges()

func speak(text: String, channel := "interface", preview := false) -> void:
	if _suspended or (not enabled() and not preview):
		return
	# Um clique pode focar a pista e logo depois a primeira célula.
	# Apenas o anúncio final da interação chega ao sintetizador.
	_scheduled = {"text": text, "channel": channel, "preview": preview}
	_speak_at = Time.get_ticks_msec() + FOCUS_DELAY_MS

func _speak_now(text: String, channel: String, preview: bool) -> void:
	if _suspended or (not enabled() and not preview):
		return
	if voice_id.is_empty():
		refresh_voices()
	if _loading:
		_pending_speech = {"text": text, "channel": channel, "preview": preview}
		return
	text = plain_text(text)
	if voice_id.is_empty() or text.is_empty():
		return
	_channel = channel
	# TTS usa a saída do sistema, por isso aplicamos o volume geral explicitamente.
	var volume := int(100.0 * float(Settings.get_setting("speech_volume", 1.0)) * float(Settings.get_setting("master_volume", 1.0)))
	if volume <= 0:
		return
	var rate := clampf(float(Settings.get_setting("speech_rate", 1.0)), 0.5, 2.0)
	_utterance_id += 1
	_start_deadline = Time.get_ticks_msec() + START_TIMEOUT_MS
	if _linux != null:
		_linux.speak(text, voice_id, float(Settings.get_setting("speech_volume", 1.0)), rate, _utterance_id)
		return
	_guard_native(DisplayServer.tts_speak.bind(text, voice_id, clampi(volume, 0, 100), 1.0, rate, _utterance_id, true))

func stop() -> void:
	_scheduled = {}
	_pending_speech = {}
	_start_deadline = 0
	if _linux != null:
		if not _loading:
			_linux.stop()
	elif not _channel.is_empty() and not _suspended and DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		_guard_native(DisplayServer.tts_stop)
	_channel = ""

func test_voice(reload_voices := false) -> void:
	if reload_voices:
		if _loading:
			return
		_suspended = false
		_notice.hide()
		voice_id = ""
		_voices_loaded = false
	refresh_voices()
	speak("Olá! Sou a voz de leitura do Garibot. Vou ajudar você a ouvir os menus e as falas.", "preview", true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_R:
			Settings.set_setting("screen_reader", not enabled())
			get_viewport().set_input_as_handled()

func _on_setting_changed(key: String, value: Variant) -> void:
	match key:
		"screen_reader":
			stop()
			if bool(value):
				refresh_voices()
				speak("Leitura em voz alta ativada. Use Tab para navegar e Enter ou Espaço para selecionar. Control Shift R desativa a leitura.")
		"speech_voice":
			refresh_voices()
		"narrate_dialogue":
			if not bool(value):
				_stop_dialogue()
		"master_volume", "speech_volume":
			if float(value) <= 0.0:
				stop()

func _hook_tree(node: Node) -> void:
	_hook_control(node)
	for child in node.get_children():
		_hook_tree(child)

func _on_node_added(node: Node) -> void:
	if node is BaseButton or node is PopupMenu or (node is Range and not node is ScrollBar):
		_hook_control.call_deferred(node)

func _hook_control(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is Range and not node is ScrollBar:
		var callback := _on_control_value_changed.bind(node)
		if not node.value_changed.is_connected(callback):
			node.value_changed.connect(callback)
	elif node is BaseButton:
		var callback := _on_control_value_changed.bind(node)
		if not node.toggled.is_connected(callback):
			node.toggled.connect(callback)
	if node is PopupMenu and not node.id_focused.is_connected(_on_popup_focused.bind(node)):
		node.id_focused.connect(_on_popup_focused.bind(node))

func _on_popup_focused(id: int, popup: PopupMenu) -> void:
	speak(popup.get_item_text(popup.get_item_index(id)))

func _on_control_value_changed(_value: Variant, control: Control) -> void:
	if not enabled():
		return
	# Aguarda o controle atualizar sua preferência e seu rótulo.
	_announce_changed_control.call_deferred(control)

func _announce_changed_control(control: Control) -> void:
	if is_instance_valid(control) and control.has_focus():
		# A ativação tem sua própria mensagem de orientação.
		if control.get_parent().get("settings_key") == "screen_reader":
			return
		_on_focus_changed(control)

func _on_focus_changed(control: Control) -> void:
	if not enabled() or not is_instance_valid(control) or not control.is_visible_in_tree():
		return
	if bool(control.get_meta("speech_managed", false)):
		return
	var label := str(control.get_meta("speech_label", ""))
	var parent := control.get_parent()
	if label.is_empty() and parent != null and parent.get("label_text") != null:
		label = str(parent.get("label_text"))
	if control is OptionButton:
		label += ". " + control.text
	elif control is BaseButton:
		if label.is_empty():
			label = control.text
		if control.toggle_mode:
			label += ". Ativado" if control.button_pressed else ". Desativado"
	elif control is Range:
		label += ". %s. Use as setas para ajustar" % str(control.value)
	elif control is LineEdit:
		label += ". " + (control.placeholder_text if control.text.is_empty() else control.text)
	if label.is_empty():
		label = control.tooltip_text
	speak(label)

func _setup_dialogic() -> void:
	if Dialogic.has_subsystem("Text"):
		Dialogic.Text.text_started.connect(_on_dialogue_text)
		Dialogic.Text.textbox_visibility_changed.connect(_on_textbox_visibility_changed)
	Dialogic.timeline_ended.connect(_stop_dialogue)

func _on_dialogue_text(info: Dictionary) -> void:
	if not enabled() or not bool(Settings.get_setting("narrate_dialogue", true)):
		return
	_stop_dialogue()
	# Uma futura dublagem configurada no Dialogic tem prioridade sobre TTS.
	if Dialogic.has_subsystem("Voice") and Dialogic.Voice.voice_player.playing:
		return
	var text := str(info.get("text", ""))
	var character = info.get("character")
	if character != null:
		text = str(Dialogic.Text.get_character_name_parsed(character)) + ". " + text
	speak(text, "dialogue")

func _on_textbox_visibility_changed(visible: bool) -> void:
	if not visible:
		_stop_dialogue()

func _stop_dialogue() -> void:
	if _channel == "dialogue" or _pending_speech.get("channel", "") == "dialogue" or _scheduled.get("channel", "") == "dialogue":
		stop()
