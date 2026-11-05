class_name AnalyticsExporter
extends RefCounted

## Monta a planilha de análise a partir dos arquivos .jsonl das sessões.
##
## Gera, na pasta de destino:
##   garibot_analise.xlsx  uma aba por tabela (abre no Excel, LibreOffice, Google Planilhas)
##   <aba>.csv             as mesmas tabelas em CSV (UTF-8 com BOM, separador ";")

const CSV_SEPARATOR := ";"
const XLSX_NAME := "garibot_analise.xlsx"

## Colunas comuns a todas as linhas, nesta ordem, no início de cada aba.
const BASE_COLUMNS := ["jogador", "sessao", "momento", "t_sessao", "fase", "zona", "x", "y", "evento"]

## Abas por tipo de evento: [nome da aba, eventos incluídos, colunas extras].
const EVENT_SHEETS := [
	["Preferencias", ["preferencia_inicial", "preferencia_alterada"], ["chave", "valor", "antes", "depois"]],
	["Dialogos", ["dialogo_inicio", "fala", "dialogo_fim"], ["timeline", "personagem", "texto", "falas", "duracao_s"]],
	[
		"Perguntas",
		["resposta"],
		["timeline", "personagem", "pergunta", "alternativas", "escolhida", "resultado", "tentativa", "tempo_resposta_s"]
	],
	[
		"Minigames",
		["minigame_inicio", "minigame_resposta", "minigame_pulou", "minigame_fim"],
		["atividade", "correta", "perfeito", "duracao_s"]
	],
	[
		"Gameplay",
		[
			"fase_inicio", "zona_entrou", "reee_coletado", "dano", "morte", "renascimento", "queda_rio",
			"inimigo_derrotado", "pausa_aberta", "pausa_fechada", "fase_concluida"
		],
		["item", "total", "fonte", "quantidade", "bateria", "tipo", "duracao_s", "mortes", "tempo_total_s"]
	],
]

## Preferências de acessibilidade destacadas no resumo.
const ACCESSIBILITY_KEYS := [
	"screen_reader", "narrate_dialogue", "dubbed_dialogue", "high_contrast", "reduced_motion",
	"subtitles", "dialog_font_size", "text_speed"
]


## Exporta tudo e retorna o caminho do .xlsx ("" se não houver dados).
static func export_all(sessions_dir: String, target_dir: String) -> String:
	var rows := _load_rows(sessions_dir)
	if rows.is_empty():
		push_warning("Analytics: nenhum dado para exportar em %s." % sessions_dir)
		return ""
	DirAccess.make_dir_recursive_absolute(target_dir)
	var tables := build_tables(rows)
	var xlsx := XlsxWriter.new()
	for table_name: String in tables:
		xlsx.add_sheet(table_name, tables[table_name])
		_write_csv("%s/%s.csv" % [target_dir, table_name.to_lower()], tables[table_name])
	var xlsx_path := "%s/%s" % [target_dir, XLSX_NAME]
	var error := xlsx.save(xlsx_path)
	if error != OK:
		push_warning("Analytics: falha ao salvar %s (erro %d)." % [xlsx_path, error])
		return ""
	return xlsx_path


## Tabelas (nome da aba -> linhas, primeira linha = cabeçalho), na ordem das abas.
static func build_tables(rows: Array[Dictionary]) -> Dictionary:
	var tables := {}
	tables["Resumo"] = _summary(rows)
	tables["Sessoes"] = _sessions(rows)
	for spec: Array in EVENT_SHEETS:
		var events: Array = spec[1]
		var selected := rows.filter(func(row: Dictionary) -> bool: return row.get("evento") in events)
		tables[spec[0]] = _table(selected, BASE_COLUMNS + spec[2])
	tables["Eventos"] = _table(rows, _all_columns(rows))
	return tables


static func _load_rows(sessions_dir: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var dir := DirAccess.open(sessions_dir)
	if dir == null:
		return rows
	var files := Array(dir.get_files()).filter(func(f: String) -> bool: return f.ends_with(".jsonl"))
	files.sort()
	for file_name: String in files:
		rows.append_array(AnalyticsLocalSink.read_rows("%s/%s" % [sessions_dir, file_name]))
	return rows


static func _table(rows: Array, columns: Array) -> Array:
	var table: Array = [columns]
	for row: Dictionary in rows:
		var line: Array = []
		for column in columns:
			line.append(row.get(column, ""))
		table.append(line)
	return table


static func _all_columns(rows: Array[Dictionary]) -> Array:
	var columns: Array = BASE_COLUMNS.duplicate()
	for row in rows:
		for key in row:
			if not key in columns:
				columns.append(key)
	return columns


static func _sessions(rows: Array[Dictionary]) -> Array:
	var order: Array = []
	var by_session := {}
	for row in rows:
		var id: String = str(row.get("sessao", ""))
		if not by_session.has(id):
			order.append(id)
			by_session[id] = {
				"jogador": row.get("jogador", ""), "sessao": id, "inicio": row.get("momento", ""),
				"fim": "", "duracao_s": 0.0, "eventos": 0, "versao": "", "plataforma": "", "idioma": "",
				"resolucao": "", "fase_concluida": false, "mortes": 0, "respostas_certas": 0, "respostas_erradas": 0,
			}
		var session: Dictionary = by_session[id]
		session["fim"] = row.get("momento", "")
		session["duracao_s"] = maxf(float(session["duracao_s"]), float(row.get("t_sessao", 0.0)))
		session["eventos"] += 1
		match row.get("evento"):
			"sessao_inicio":
				for key in ["versao", "plataforma", "idioma", "resolucao"]:
					session[key] = row.get(key, "")
			"fase_concluida":
				session["fase_concluida"] = true
			"morte":
				session["mortes"] += 1
			"resposta":
				if row.get("resultado") == "certa":
					session["respostas_certas"] += 1
				elif row.get("resultado") == "errada":
					session["respostas_erradas"] += 1
	var columns := [
		"jogador", "sessao", "inicio", "fim", "duracao_s", "eventos", "versao", "plataforma", "idioma",
		"resolucao", "fase_concluida", "mortes", "respostas_certas", "respostas_erradas"
	]
	var sessions: Array = []
	for id in order:
		sessions.append(by_session[id])
	return _table(sessions, columns)


## Uma linha por jogador com os indicadores principais para análise.
static func _summary(rows: Array[Dictionary]) -> Array:
	var order: Array = []
	var players := {}
	for row in rows:
		var id: String = str(row.get("jogador", ""))
		if not players.has(id):
			order.append(id)
			players[id] = {
				"jogador": id, "sessoes": {}, "tempo_total_s": 0.0, "respostas": 0, "certas": 0,
				"certas_1a_tentativa": 0, "ouvir_de_novo": 0, "mortes": 0, "danos": 0, "reee_coletados": 0,
				"minigames_concluidos": 0, "minigames_pulados": 0, "fases_concluidas": 0,
				"preferencias_alteradas": {}, "prefs": {},
			}
		var player: Dictionary = players[id]
		var session_id := str(row.get("sessao", ""))
		player["sessoes"][session_id] = maxf(float(player["sessoes"].get(session_id, 0.0)), float(row.get("t_sessao", 0.0)))
		match row.get("evento"):
			"resposta":
				match row.get("resultado"):
					"ouvir_de_novo":
						player["ouvir_de_novo"] += 1
					"certa":
						player["respostas"] += 1
						player["certas"] += 1
						if int(row.get("tentativa", 0)) == 1:
							player["certas_1a_tentativa"] += 1
					_:
						player["respostas"] += 1
			"morte":
				player["mortes"] += 1
			"dano":
				player["danos"] += 1
			"reee_coletado":
				player["reee_coletados"] += 1
			"minigame_fim":
				player["minigames_concluidos"] += 1
			"minigame_pulou":
				player["minigames_pulados"] += 1
			"fase_concluida":
				player["fases_concluidas"] += 1
			"preferencia_inicial":
				player["prefs"][row.get("chave")] = row.get("valor")
			"preferencia_alterada":
				player["prefs"][row.get("chave")] = row.get("depois")
				player["preferencias_alteradas"][row.get("chave")] = true
	var columns := [
		"jogador", "sessoes", "tempo_total_min", "respostas", "acerto_pct", "acerto_1a_tentativa_pct",
		"ouvir_de_novo", "mortes", "danos", "reee_coletados", "minigames_concluidos", "minigames_pulados",
		"fases_concluidas", "preferencias_alteradas"
	]
	columns.append_array(ACCESSIBILITY_KEYS)
	var lines: Array = []
	for id in order:
		var p: Dictionary = players[id]
		var total := 0.0
		for seconds in p["sessoes"].values():
			total += float(seconds)
		var answers: int = p["respostas"]
		var line := p.duplicate()
		line["sessoes"] = p["sessoes"].size()
		line["tempo_total_min"] = snappedf(total / 60.0, 0.1)
		line["acerto_pct"] = snappedf(100.0 * p["certas"] / answers, 0.1) if answers > 0 else ""
		line["acerto_1a_tentativa_pct"] = (
			snappedf(100.0 * p["certas_1a_tentativa"] / p["certas"], 0.1) if p["certas"] > 0 else ""
		)
		line["preferencias_alteradas"] = ", ".join(PackedStringArray(p["preferencias_alteradas"].keys()))
		for key in ACCESSIBILITY_KEYS:
			line[key] = p["prefs"].get(key, "")
		lines.append(line)
	return _table(lines, columns)


static func _write_csv(path: String, table: Array) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	# BOM: o Excel reconhece UTF-8 e mostra os acentos corretamente.
	file.store_buffer(PackedByteArray([0xEF, 0xBB, 0xBF]))
	for row: Array in table:
		var cells := PackedStringArray()
		for value in row:
			cells.append(_csv_cell(value))
		file.store_string(CSV_SEPARATOR.join(cells) + "\r\n")
	file.close()


static func _csv_cell(value: Variant) -> String:
	var text := str(value)
	if typeof(value) == TYPE_FLOAT:
		# Excel em pt-BR usa vírgula decimal.
		text = text.replace(".", ",")
	if text.contains(CSV_SEPARATOR) or text.contains('"') or text.contains("\n"):
		text = '"%s"' % text.replace('"', '""')
	return text
