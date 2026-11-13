class_name BossAttack
extends Node2D

## Base dos ataques de chefe. Cada ataque é um nó filho do chefe (no grupo de ataques)
## e roda de forma independente: o chefe pergunta `can_start(boss)`, chama
## `start(boss)` e espera `finished`.
##
## Para criar um ataque novo: estenda esta classe, implemente `_perform()` (pode usar
## `await`) e, se deixar algo na tela, limpe em `_cleanup()`. `stop()` interrompe o
## ataque a qualquer momento (ex.: chefe derrotado) e também emite `finished`.
##
## O nó fica em coordenadas globais (`top_level`), então pode desenhar avisos no chão
## mesmo sendo filho de um chefe que voa.

signal finished

## Nome do ataque na telemetria.
@export var attack_id := "ataque"
## Pausa depois do ataque, antes de devolver a vez ao chefe (s).
@export var recovery_time := 0.6

var boss: Node2D
var running := false
## Muda a cada `start`: corrotinas antigas sabem que foram canceladas.
var _run_id := 0


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO


## O chefe só escolhe este ataque se ele puder rodar agora (sobrescreva para limitar,
## ex.: invocação com o máximo de lacaios já na arena).
func can_start(_attacker: Node2D) -> bool:
	return true


func start(attacker: Node2D) -> void:
	boss = attacker
	running = true
	_run_id += 1
	var run := _run_id
	await _perform()
	if run != _run_id or not running:
		return
	await wait(recovery_time)
	if run != _run_id or not running:
		return
	_end()


func stop() -> void:
	if not running:
		return
	_run_id += 1
	_end()


## Espera que respeita o cancelamento: devolve `false` se o ataque foi parado.
func wait(seconds: float) -> bool:
	var run := _run_id
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
	return run == _run_id and running


func _end() -> void:
	running = false
	_cleanup()
	queue_redraw()
	finished.emit()


## O ataque em si (sobrescreva). Use `if not await wait(t): return` entre as etapas.
func _perform() -> void:
	pass


## Remove avisos, sobreposições etc. (sobrescreva se precisar).
func _cleanup() -> void:
	pass


func reduced_motion() -> bool:
	return bool(Settings.get_setting("reduced_motion", false))
