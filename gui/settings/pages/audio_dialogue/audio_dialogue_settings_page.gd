extends VBoxContainer

const AUTO_LABEL := "Português (Brasil) — automático"
var _rows_revision := -1
var _labels: Dictionary = {}

@onready var voice_button: Button = $Voice
@onready var picker: VBoxContainer = $VoicePicker
@onready var search: LineEdit = $VoicePicker/Search
@onready var results: VBoxContainer = $VoicePicker/Results/ContentMargin/List
@onready var result_count: Label = $VoicePicker/ResultCount
@onready var speech_status: Label = $SpeechStatus

func _ready() -> void:
	voice_button.pressed.connect(_toggle_picker)
	search.text_changed.connect(_filter_voices)
	search.text_submitted.connect(_focus_first_result)
	$TestVoice.pressed.connect(_on_test_voice)
	Settings.setting_changed.connect(_on_setting_changed)
	Speech.status_changed.connect(_on_speech_status_changed)
	Speech.voices_changed.connect(_on_voices_changed)
	visibility_changed.connect(_on_visibility_changed)
	if is_visible_in_tree():
		_refresh_voices()

func _refresh_voices() -> void:
	Speech.refresh_voices()
	var preferred := str(Settings.get_setting("speech_voice", ""))
	var label := AUTO_LABEL
	for voice in Speech.voices:
		if str(voice["id"]) == preferred:
			label = _voice_label(voice)
	voice_button.text = "Voz: " + label
	voice_button.tooltip_text = voice_button.text
	voice_button.set_meta("speech_label", voice_button.text)
	speech_status.text = Speech.status_text
	if picker.visible:
		_filter_voices(search.text)

func _voice_label(voice: Dictionary) -> String:
	var id := str(voice["id"])
	if _labels.has(id):
		return _labels[id]
	var locale := str(voice["language"]).replace("_", "-")
	var language := TranslationServer.get_locale_name(locale.replace("-", "_"))
	if locale.to_lower().begins_with("pt-br"):
		language = "Português (Brasil)"
	elif locale.to_lower().begins_with("pt"):
		language = "Português (Portugal)" if locale.to_lower() == "pt-pt" else "Português"
	elif locale.to_lower().begins_with("en"):
		language = "Inglês / " + language
	elif locale.to_lower().begins_with("es"):
		language = "Espanhol / " + language
	var label := "%s · %s · %s" % [language, locale, voice["name"]]
	_labels[id] = label
	return label

func _search_key(value: String) -> String:
	value = value.to_lower().replace("_", "-")
	for pair in [["á", "a"], ["ã", "a"], ["â", "a"], ["é", "e"], ["ê", "e"], ["í", "i"], ["ó", "o"], ["õ", "o"], ["ô", "o"], ["ú", "u"], ["ç", "c"]]:
		value = value.replace(pair[0], pair[1])
	return value.strip_edges()

func _filter_voices(query: String) -> void:
	_ensure_voice_rows()
	var key := _search_key(query)
	var count := 0
	var preferred := str(Settings.get_setting("speech_voice", ""))
	for button in results.get_children():
		button.visible = key.is_empty() or str(button.get_meta("search_key")).contains(key)
		button.set_pressed_no_signal(str(button.get_meta("voice_id")) == preferred)
		if button.visible and str(button.get_meta("voice_id")) != "":
			count += 1
	result_count.text = "%d vozes encontradas" % count if count > 0 else "Nenhuma voz encontrada. Tente outro idioma ou instale uma voz no sistema."
	$VoicePicker/Results.scroll_vertical = 0

func _ensure_voice_rows() -> void:
	if _rows_revision == Speech.voices_revision:
		return
	_rows_revision = Speech.voices_revision
	_labels.clear()
	for child in results.get_children():
		results.remove_child(child)
		child.queue_free()
	_add_voice_button(AUTO_LABEL, "")
	for voice in Speech.voices:
		_add_voice_button(_voice_label(voice), str(voice["id"]))

func _add_voice_button(label: String, id: String) -> void:
	var button := Button.new()
	button.text = label
	button.tooltip_text = label
	button.clip_text = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.theme_type_variation = &"VoiceListButton"
	button.toggle_mode = true
	button.set_meta("voice_id", id)
	button.set_meta("search_key", _search_key(label + (" pt-BR" if id.is_empty() else "")))
	button.button_pressed = id == str(Settings.get_setting("speech_voice", ""))
	button.pressed.connect(_select_voice.bind(id))
	results.add_child(button)

func _toggle_picker() -> void:
	picker.visible = not picker.visible
	if picker.visible:
		_refresh_voices()
		search.grab_focus()

func _focus_first_result(_text: String) -> void:
	for button in results.get_children():
		if button.visible:
			button.grab_focus()
			return

func _select_voice(id: String) -> void:
	# Deferir evita remover o botão enquanto seu sinal ainda está sendo emitido.
	_commit_voice.call_deferred(id)

func _commit_voice(id: String) -> void:
	picker.hide()
	Settings.set_setting("speech_voice", id)
	_refresh_voices()
	voice_button.grab_focus()
	Speech.test_voice()

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and picker.visible and event.is_action_pressed("ui_cancel"):
		picker.hide()
		voice_button.grab_focus()
		get_viewport().set_input_as_handled()

func _on_test_voice() -> void:
	Speech.test_voice(true)
	_labels.clear()
	_refresh_voices()

func _on_visibility_changed() -> void:
	if is_node_ready():
		picker.hide()
		if is_visible_in_tree():
			_refresh_voices()

func _on_setting_changed(key: String, _value: Variant) -> void:
	if key in ["speech_voice", "screen_reader"]:
		_refresh_voices()

func _on_speech_status_changed(message: String) -> void:
	speech_status.text = message

func _on_voices_changed() -> void:
	_labels.clear()
	_refresh_voices()
