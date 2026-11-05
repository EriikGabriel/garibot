extends Node

## Telemetria do jogo para análise posterior (autoload `Analytics`).
##
## Registra decisões e dados úteis do jogador: preferências, diálogos, respostas
## às perguntas, minigames, coleta, dano, mortes e tempos. Cada evento vira uma
## linha em user://analytics/sessions/<data>_<sessão>.jsonl; `export_data()` gera
## a planilha (.xlsx com abas + CSVs) numa pasta separada.
##
## Uso no código do jogo: `Analytics.track("evento", {"campo": valor})`.
## Contexto comum (fase, zona, posição) vem de `set_context()` e `set_tracked_node()`.
##
## Privacidade: o jogador é identificado só por um ID aleatório gerado no aparelho.
## O envio remoto (opcional) depende de REMOTE_URL e do consentimento nas preferências.
## Esquema dos eventos e configuração do envio: docs/analytics.md.

## Liga/desliga todo o sistema. Com false, nenhuma chamada grava nada.
const ENABLED := true
## Endpoint para envio remoto em lote (vazio = só local). Ver docs/analytics.md.
const REMOTE_URL := ""
const SCHEMA_VERSION := 1

const ROOT_DIR := "user://analytics"
const SESSIONS_DIR := ROOT_DIR + "/sessions"
const EXPORTS_DIR := ROOT_DIR + "/exports"
const PLAYER_FILE := ROOT_DIR + "/player.cfg"
const PENDING_FILE := ROOT_DIR + "/pending.jsonl"
## Texto da alternativa que repete a explicação nos diálogos.
const LISTEN_AGAIN_TEXT := "ouvir de novo"
## Mudanças contínuas (sliders) viram um único evento após esta pausa (s).
const SETTING_DEBOUNCE := 1.0

signal exported(folder: String)

var player_id := ""
var session_id := ""

var _session_start_ms := 0
var _context := {"fase": "", "zona": ""}
var _tracked_node: Node2D
var _local: AnalyticsLocalSink
var _remote: AnalyticsRemoteSink
var _ended := false

var _settings_cache := {}
var _pending_settings := {}
var _settings_timer: Timer

var _timeline := ""
var _timeline_start_ms := 0
var _timeline_lines := 0
var _last_line := {"personagem": "", "texto": ""}
var _question := {}
var _pending_answer := {}
var _attempts := {}


func _ready() -> void:
	if not ENABLED:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(SESSIONS_DIR)
	player_id = _load_or_create_player_id()
	session_id = _random_id(8)
	_session_start_ms = Time.get_ticks_msec()
	var stamp := Time.get_datetime_string_from_system(false, false).replace(":", "-").replace("T", "_")
	_local = AnalyticsLocalSink.new("%s/%s_%s.jsonl" % [SESSIONS_DIR, stamp, session_id])
	if not REMOTE_URL.is_empty():
		_remote = AnalyticsRemoteSink.new()
		add_child(_remote)
		_remote.setup(REMOTE_URL, PENDING_FILE)
	_start_session()
	_settings_timer = Timer.new()
	_settings_timer.one_shot = true
	_settings_timer.wait_time = SETTING_DEBOUNCE
	_settings_timer.timeout.connect(_flush_settings)
	add_child(_settings_timer)
	Settings.setting_changed.connect(_on_setting_changed)
	# O Dialogic termina de montar os subsistemas depois do primeiro quadro.
	get_tree().process_frame.connect(_hook_dialogic, CONNECT_ONE_SHOT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		end_session()


## Registra um evento. `data` é mesclado às colunas comuns da linha.
func track(event: String, data := {}) -> void:
	if not ENABLED or _local == null:
		return
	var row := {
		"jogador": player_id,
		"sessao": session_id,
		"momento": Time.get_datetime_string_from_system(false, true),
		"t_sessao": snappedf((Time.get_ticks_msec() - _session_start_ms) / 1000.0, 0.01),
		"fase": _context.get("fase", ""),
		"zona": _context.get("zona", ""),
		"x": "",
		"y": "",
		"evento": event,
	}
	if is_instance_valid(_tracked_node) and _tracked_node.is_inside_tree():
		row["x"] = roundi(_tracked_node.global_position.x)
		row["y"] = roundi(_tracked_node.global_position.y)
	for key in data:
		row[key] = _plain(data[key])
	_local.write(row)
	if _remote and Settings.get_setting("analytics_consent", true):
		_remote.enqueue(row)


## Atualiza o contexto comum (ex.: {"fase": "fase1", "zona": "Parque"}).
func set_context(values: Dictionary) -> void:
	_context.merge(values, true)


## Nó cuja posição acompanha cada evento (normalmente o Player).
func set_tracked_node(node: Node2D) -> void:
	_tracked_node = node


## Gera a planilha com todas as sessões gravadas. Retorna a pasta criada ("" se desligado).
## `open_folder` abre a pasta no desktop; na Web, o .xlsx é baixado pelo navegador.
func export_data(open_folder := true, folder_name := "") -> String:
	if not ENABLED:
		return ""
	_flush_settings()
	var export_name := folder_name
	if export_name.is_empty():
		export_name = Time.get_datetime_string_from_system(false, false).replace(":", "-").replace("T", "_")
	var folder := "%s/%s" % [EXPORTS_DIR, export_name]
	var xlsx_path := AnalyticsExporter.export_all(SESSIONS_DIR, folder)
	if xlsx_path.is_empty():
		return ""
	if OS.has_feature("web"):
		var bytes := FileAccess.get_file_as_bytes(xlsx_path)
		JavaScriptBridge.download_buffer(
			bytes,
			"garibot_analise_%s.xlsx" % export_name,
			"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
		)
	elif open_folder:
		OS.shell_open(ProjectSettings.globalize_path(folder))
	exported.emit(folder)
	return folder


## Encerra a sessão (chamado ao fechar o jogo).
func end_session() -> void:
	if not ENABLED or _ended or _local == null:
		return
	_ended = true
	_flush_settings()
	_finish_pending_answer("errada")
	track("sessao_fim", {"duracao_s": snappedf((Time.get_ticks_msec() - _session_start_ms) / 1000.0, 0.1)})
	if _remote:
		_remote.persist_unsent()
	_local.close()


func _unhandled_input(event: InputEvent) -> void:
	# Atalho de desenvolvimento: F9 exporta a planilha e abre a pasta.
	if (
		ENABLED
		and OS.is_debug_build()
		and event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_F9
	):
		export_data()
		get_viewport().set_input_as_handled()


func _start_session() -> void:
	var window := DisplayServer.window_get_size()
	track(
		"sessao_inicio",
		{
			"versao": str(ProjectSettings.get_setting("application/config/version", "dev")),
			"esquema": SCHEMA_VERSION,
			"plataforma": OS.get_name(),
			"idioma": OS.get_locale(),
			"resolucao": "%dx%d" % [window.x, window.y],
			"build_debug": OS.is_debug_build(),
		}
	)
	for key in Settings.settings:
		_settings_cache[key] = _plain(Settings.settings[key])
		track("preferencia_inicial", {"chave": key, "valor": _settings_cache[key]})


# --- Preferências -------------------------------------------------------------


func _on_setting_changed(key: String, value: Variant) -> void:
	var entry: Dictionary = _pending_settings.get(key, {"antes": _settings_cache.get(key, "")})
	entry["depois"] = _plain(value)
	_pending_settings[key] = entry
	_settings_cache[key] = entry["depois"]
	_settings_timer.start()


func _flush_settings() -> void:
	for key in _pending_settings:
		var entry: Dictionary = _pending_settings[key]
		if str(entry["antes"]) != str(entry["depois"]):
			track("preferencia_alterada", {"chave": key, "antes": entry["antes"], "depois": entry["depois"]})
	_pending_settings.clear()


# --- Diálogos e perguntas -----------------------------------------------------


func _hook_dialogic() -> void:
	if not has_node("/root/Dialogic"):
		return
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.Text.about_to_show_text.connect(_on_text_shown)
	Dialogic.Choices.question_shown.connect(_on_question_shown)
	Dialogic.Choices.choice_selected.connect(_on_choice_selected)


func _on_timeline_started() -> void:
	var timeline: Resource = Dialogic.current_timeline
	_timeline = timeline.resource_path.get_file().get_basename() if timeline else ""
	_timeline_start_ms = Time.get_ticks_msec()
	_timeline_lines = 0
	track("dialogo_inicio", {"timeline": _timeline})


func _on_timeline_ended() -> void:
	_finish_pending_answer("errada")
	track(
		"dialogo_fim",
		{
			"timeline": _timeline,
			"duracao_s": snappedf((Time.get_ticks_msec() - _timeline_start_ms) / 1000.0, 0.1),
			"falas": _timeline_lines,
		}
	)
	_timeline = ""


func _on_text_shown(info: Dictionary) -> void:
	_timeline_lines += 1
	var character: Resource = info.get("character")
	_last_line = {
		"personagem": character.display_name if character and "display_name" in character else "",
		"texto": _plain(str(info.get("text", ""))),
	}
	track("fala", {"timeline": _timeline, "personagem": _last_line["personagem"], "texto": _last_line["texto"]})


func _on_question_shown(info: Dictionary) -> void:
	# Pergunta reaparecendo = a resposta anterior estava errada.
	_finish_pending_answer("errada")
	var options := PackedStringArray()
	for choice: Dictionary in info.get("choices", []):
		options.append(_plain(str(choice.get("text", ""))))
	_question = {
		"timeline": _timeline,
		"personagem": _last_line["personagem"],
		"pergunta": _last_line["texto"],
		"alternativas": " | ".join(options),
		"mostrada_ms": Time.get_ticks_msec(),
	}


func _on_choice_selected(info: Dictionary) -> void:
	if _question.is_empty():
		return
	var chosen: String = _plain(str(info.get("text", "")))
	var key := "%s|%s" % [_question["timeline"], _question["pergunta"]]
	var listen_again: bool = chosen.to_lower().strip_edges() == LISTEN_AGAIN_TEXT
	if not listen_again:
		_attempts[key] = int(_attempts.get(key, 0)) + 1
	var row := {
		"timeline": _question["timeline"],
		"personagem": _question["personagem"],
		"pergunta": _question["pergunta"],
		"alternativas": _question["alternativas"],
		"escolhida": chosen,
		"tentativa": _attempts.get(key, 0),
		"tempo_resposta_s": snappedf((Time.get_ticks_msec() - int(_question["mostrada_ms"])) / 1000.0, 0.01),
	}
	if listen_again:
		row["resultado"] = "ouvir_de_novo"
		track("resposta", row)
	else:
		# O acerto só é conhecido depois: sinal "acerto" ou a pergunta reaparecendo.
		_pending_answer = row


func _on_dialogic_signal(argument: Variant) -> void:
	if str(argument) == "acerto":
		_finish_pending_answer("certa")


func _finish_pending_answer(result: String) -> void:
	if _pending_answer.is_empty():
		return
	_pending_answer["resultado"] = result
	track("resposta", _pending_answer)
	_pending_answer = {}


# --- Utilitários --------------------------------------------------------------


func _load_or_create_player_id() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(PLAYER_FILE) == OK and cfg.has_section_key("jogador", "id"):
		return str(cfg.get_value("jogador", "id"))
	var id := _random_id(12)
	cfg.set_value("jogador", "id", id)
	cfg.set_value("jogador", "criado_em", Time.get_datetime_string_from_system(false, true))
	cfg.save(PLAYER_FILE)
	return id


func _random_id(length: int) -> String:
	const ALPHABET := "abcdefghjkmnpqrstuvwxyz23456789"
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var id := ""
	for i in length:
		id += ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)]
	return id


## Valores simples para planilha: texto sem BBCode, dicionários/arrays em JSON.
func _plain(value: Variant) -> Variant:
	match typeof(value):
		TYPE_STRING, TYPE_STRING_NAME:
			var regex := RegEx.create_from_string("\\[[^\\]]*\\]")
			return regex.sub(str(value), "", true).strip_edges()
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
			return value
		TYPE_DICTIONARY, TYPE_ARRAY:
			return JSON.stringify(value)
		TYPE_NIL:
			return ""
	return str(value)
