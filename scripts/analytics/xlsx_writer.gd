class_name XlsxWriter
extends RefCounted

## Gera um .xlsx (Office Open XML) mínimo com várias abas, sem dependências:
## o arquivo é um ZIP de XMLs montado com ZIPPacker. Cabeçalho em negrito,
## primeira linha congelada, filtro automático e largura de coluna ajustada.
## Textos vão como "inlineStr"; números e booleanos como valores numéricos.

const MAX_COLUMN_WIDTH := 60
const MAX_SHEET_NAME := 31

## Cada aba: {"name": String, "rows": Array (a primeira linha é o cabeçalho)}.
var _sheets: Array[Dictionary] = []


func add_sheet(sheet_name: String, rows: Array) -> void:
	_sheets.append({"name": sheet_name.left(MAX_SHEET_NAME), "rows": rows})


func save(path: String) -> Error:
	var zip := ZIPPacker.new()
	var error := zip.open(path)
	if error != OK:
		return error
	_add(zip, "[Content_Types].xml", _content_types())
	_add(zip, "_rels/.rels", _root_rels())
	_add(zip, "xl/workbook.xml", _workbook())
	_add(zip, "xl/_rels/workbook.xml.rels", _workbook_rels())
	_add(zip, "xl/styles.xml", _styles())
	for i in _sheets.size():
		_add(zip, "xl/worksheets/sheet%d.xml" % (i + 1), _sheet_xml(_sheets[i]["rows"]))
	return zip.close()


func _add(zip: ZIPPacker, file_name: String, content: String) -> void:
	zip.start_file(file_name)
	zip.write_file(content.to_utf8_buffer())
	zip.close_file()


func _content_types() -> String:
	var sheets := ""
	for i in _sheets.size():
		sheets += (
			'<Override PartName="/xl/worksheets/sheet%d.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
			% (i + 1)
		)
	return (
		'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
		+ '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
		+ '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
		+ '<Default Extension="xml" ContentType="application/xml"/>'
		+ '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
		+ '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
		+ sheets
		+ "</Types>"
	)


func _root_rels() -> String:
	return (
		'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
		+ '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
		+ '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
		+ "</Relationships>"
	)


func _workbook() -> String:
	var sheets := ""
	for i in _sheets.size():
		sheets += '<sheet name="%s" sheetId="%d" r:id="rId%d"/>' % [_escape(_sheets[i]["name"]), i + 1, i + 1]
	return (
		'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
		+ '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
		+ 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
		+ "<sheets>%s</sheets></workbook>" % sheets
	)


func _workbook_rels() -> String:
	var rels := ""
	for i in _sheets.size():
		rels += (
			'<Relationship Id="rId%d" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet%d.xml"/>'
			% [i + 1, i + 1]
		)
	rels += (
		'<Relationship Id="rId%d" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
		% (_sheets.size() + 1)
	)
	return (
		'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
		+ '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
		+ rels
		+ "</Relationships>"
	)


## Estilo 0 = normal; estilo 1 = cabeçalho em negrito com fundo creme.
func _styles() -> String:
	return (
		'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
		+ '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
		+ '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
		+ '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
		+ '<fills count="3"><fill><patternFill patternType="none"/></fill>'
		+ '<fill><patternFill patternType="gray125"/></fill>'
		+ '<fill><patternFill patternType="solid"><fgColor rgb="FFF2EAD3"/><bgColor indexed="64"/></patternFill></fill></fills>'
		+ '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
		+ '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
		+ '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
		+ '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/></cellXfs>'
		+ "</styleSheet>"
	)


func _sheet_xml(rows: Array) -> String:
	var columns := 0
	for row: Array in rows:
		columns = maxi(columns, row.size())
	var widths := PackedInt32Array()
	widths.resize(columns)
	for row: Array in rows:
		for c in row.size():
			widths[c] = mini(maxi(widths[c], str(row[c]).length() + 2), MAX_COLUMN_WIDTH)
	var parts := PackedStringArray()
	parts.append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
	parts.append('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">')
	parts.append(
		'<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
	)
	if columns > 0:
		parts.append("<cols>")
		for c in columns:
			parts.append('<col min="%d" max="%d" width="%d" customWidth="1"/>' % [c + 1, c + 1, maxi(widths[c], 8)])
		parts.append("</cols>")
	parts.append("<sheetData>")
	for r in rows.size():
		var row: Array = rows[r]
		parts.append('<row r="%d">' % (r + 1))
		for c in row.size():
			parts.append(_cell(row[c], "%s%d" % [column_name(c), r + 1], r == 0))
		parts.append("</row>")
	parts.append("</sheetData>")
	if rows.size() > 1 and columns > 0:
		parts.append('<autoFilter ref="A1:%s%d"/>' % [column_name(columns - 1), rows.size()])
	parts.append("</worksheet>")
	return "".join(parts)


func _cell(value: Variant, ref: String, header: bool) -> String:
	var style := ' s="1"' if header else ""
	match typeof(value):
		TYPE_INT, TYPE_FLOAT:
			return '<c r="%s"%s><v>%s</v></c>' % [ref, style, str(value)]
		TYPE_BOOL:
			return '<c r="%s"%s t="b"><v>%d</v></c>' % [ref, style, 1 if value else 0]
	var text := str(value)
	if text.is_empty():
		return '<c r="%s"%s/>' % [ref, style]
	return '<c r="%s"%s t="inlineStr"><is><t xml:space="preserve">%s</t></is></c>' % [ref, style, _escape(text)]


## Índice 0 -> "A", 25 -> "Z", 26 -> "AA".
static func column_name(index: int) -> String:
	var result := ""
	var n := index + 1
	while n > 0:
		var remainder := (n - 1) % 26
		result = char(65 + remainder) + result
		n = floori((n - 1) / 26.0)
	return result


static func _escape(text: String) -> String:
	var clean := ""
	for ch in text:
		var code := ch.unicode_at(0)
		# XML não aceita caracteres de controle (exceto tab e quebras de linha).
		if code < 32 and code != 9 and code != 10 and code != 13:
			continue
		clean += ch
	return clean.xml_escape(true)
