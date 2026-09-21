extends RefCounted
## Gerador determinístico: tenta cruzar todas as palavras, sem vizinhos laterais.
## Retorna entradas posicionadas e palavras que não couberam.
static func generate(words: Array) -> Dictionary:
	var pending: Array[Dictionary] = []
	var rejected: Array[String] = []
	for item in words:
		if not item is Dictionary:
			continue
		var answer := normalize(str(item.get("answer", "")))
		if answer.length() < 2 or str(item.get("clue", "")).is_empty():
			rejected.append(answer)
			continue
		pending.append({"answer": answer, "clue": str(item["clue"])})
	pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["answer"].length() > b["answer"].length())
	var placed: Array[Dictionary] = []
	var grid: Dictionary = {}
	while not pending.is_empty():
		var progress := false
		for item in pending.duplicate():
			var answer: String = item["answer"]
			var found := false
			var start := Vector2i.ZERO
			var direction := Vector2i.RIGHT
			if placed.is_empty():
				found = true
			else:
				for point in grid:
					for index in answer.length():
						if answer[index] != grid[point]:
							continue
						for axis in [Vector2i.RIGHT, Vector2i.DOWN]:
							var candidate: Vector2i = point - axis * index
							if fits(answer, candidate, axis, grid, placed):
								start = candidate
								direction = axis
								found = true
								break
						if found:
							break
					if found:
						break
			if not found:
				continue
			var entry: Dictionary = item.duplicate()
			entry["start"] = start
			entry["vertical"] = direction == Vector2i.DOWN
			placed.append(entry)
			for i in answer.length():
				grid[start + direction * i] = answer[i]
			pending.erase(item)
			progress = true
		if not progress:
			break
	for item in pending:
		rejected.append(str(item["answer"]))
	var origin := Vector2i.ZERO
	for point in grid:
		origin.x = mini(origin.x, point.x)
		origin.y = mini(origin.y, point.y)
	for entry in placed:
		entry["start"] -= origin
	return {"entries": placed, "unplaced": rejected}

static func normalize(value: String) -> String:
	var result := value.strip_edges().to_upper()
	var accents := "ÁÀÂÃÉÊÍÓÔÕÚÜÇ"
	var plain := "AAAAEEIOOOUUC"
	for i in accents.length():
		result = result.replace(accents[i], plain[i])
	var letters := ""
	for i in result.length():
		if result.unicode_at(i) >= 65 and result.unicode_at(i) <= 90:
			letters += result[i]
	return letters

static func fits(word: String, start: Vector2i, axis: Vector2i, grid: Dictionary, placed: Array[Dictionary]) -> bool:
	if grid.has(start - axis) or grid.has(start + axis * word.length()):
		return false
	var side := Vector2i(axis.y, axis.x)
	var crossings := 0
	for i in word.length():
		var point := start + axis * i
		if grid.has(point):
			if grid[point] != word[i]:
				return false
			for entry in placed:
				var other_axis := Vector2i.DOWN if entry["vertical"] else Vector2i.RIGHT
				if axis == other_axis:
					for j in str(entry["answer"]).length():
						if entry["start"] + other_axis * j == point:
							return false
			crossings += 1
		elif grid.has(point + side) or grid.has(point - side):
			return false
	return crossings > 0
