class_name AnalyticsLocalSink
extends RefCounted

## Grava os eventos de uma sessão em JSON Lines (um evento por linha).
## Cada linha é gravada e descarregada na hora: se o jogo fechar de repente,
## nada do que já aconteceu se perde.

var path := ""
var _file: FileAccess


func _init(file_path: String) -> void:
	path = file_path
	_file = FileAccess.open(path, FileAccess.WRITE)
	if _file == null:
		push_warning("Analytics: não foi possível criar %s (erro %d)." % [path, FileAccess.get_open_error()])


func write(row: Dictionary) -> void:
	if _file == null:
		return
	_file.store_line(JSON.stringify(row))
	_file.flush()


func close() -> void:
	if _file:
		_file.close()
		_file = null


## Lê todas as linhas de um arquivo .jsonl (linhas inválidas são ignoradas).
static func read_rows(file_path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return rows
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if parsed is Dictionary:
			rows.append(_restore_integers(parsed))
	return rows


## O JSON lê todo número como float; inteiros voltam a ser int (208 em vez de 208,0).
static func _restore_integers(row: Dictionary) -> Dictionary:
	for key in row:
		var value: Variant = row[key]
		if typeof(value) == TYPE_FLOAT and is_equal_approx(value, roundf(value)) and absf(value) < 1e15:
			row[key] = int(value)
	return row
