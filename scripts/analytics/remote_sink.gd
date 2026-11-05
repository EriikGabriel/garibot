class_name AnalyticsRemoteSink
extends Node

## Envio opcional dos eventos para um servidor, em lotes (POST JSON {"rows": [...]}).
## Pensado para um Google Apps Script que grava numa Google Planilha (ver
## docs/analytics.md), mas aceita qualquer endpoint. Sem rede, os eventos ficam
## em `pending_path` e são reenviados na próxima oportunidade.

## Envia quando a fila atinge este tamanho...
@export var batch_size := 25
## ...ou a cada este intervalo (s).
@export var send_interval := 30.0
@export var request_timeout := 15.0

var url := ""
var pending_path := ""

var _queue: Array[Dictionary] = []
var _in_flight: Array[Dictionary] = []
var _http: HTTPRequest
var _timer: Timer


func setup(endpoint: String, pending_file: String) -> void:
	url = endpoint
	pending_path = pending_file
	process_mode = Node.PROCESS_MODE_ALWAYS
	_http = HTTPRequest.new()
	_http.timeout = request_timeout
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)
	_timer = Timer.new()
	_timer.wait_time = send_interval
	_timer.autostart = true
	_timer.timeout.connect(send_now)
	add_child(_timer)
	# Recupera o que não foi enviado em sessões anteriores.
	_queue.append_array(AnalyticsLocalSink.read_rows(pending_path))
	if FileAccess.file_exists(pending_path):
		DirAccess.remove_absolute(pending_path)


func enqueue(row: Dictionary) -> void:
	_queue.append(row)
	if _queue.size() >= batch_size:
		send_now()


func send_now() -> void:
	if _queue.is_empty() or not _in_flight.is_empty() or _http == null:
		return
	_in_flight = _queue.duplicate()
	_queue.clear()
	var body := JSON.stringify({"rows": _in_flight})
	var error := _http.request(
		url, PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, body
	)
	if error != OK:
		_on_failure()


## Ao sair: o que não deu para enviar fica salvo para a próxima sessão.
func persist_unsent() -> void:
	var unsent := _merged()
	if unsent.is_empty():
		return
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(pending_path) else FileAccess.WRITE
	var file := FileAccess.open(pending_path, mode)
	if file == null:
		return
	file.seek_end()
	for row in unsent:
		file.store_line(JSON.stringify(row))
	file.close()
	_in_flight.clear()
	_queue.clear()


func _on_request_completed(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 400:
		_in_flight.clear()
		if _queue.size() >= batch_size:
			send_now()
	else:
		_on_failure()


func _on_failure() -> void:
	# Devolve o lote para a fila; tenta de novo no próximo intervalo.
	_queue = _merged()
	_in_flight.clear()


## Lote em voo (mais antigo) seguido da fila atual.
func _merged() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	rows.append_array(_in_flight)
	rows.append_array(_queue)
	return rows
