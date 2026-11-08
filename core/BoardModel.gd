class_name BoardModel
extends RefCounted
var cells: Array = []
var last_cell: int = -1
var turn: int = 1
var winner: int = 0
var win_lines: Array = []
var history: Array = []
var owners: Array = [0,1] # X/O -> human identity (not color)
var starter_owner: int = 0
var swap_enabled: bool = true
var swap_pending: bool = false
var result_recorded: bool = false
func _init() -> void:
	cells.resize(54)
	cells.fill(0)
func snapshot() -> Dictionary:
	return {"last_cell":last_cell,"starter_owner":starter_owner,"cells":cells.duplicate(),"turn":turn,"winner":winner,"owners":owners.duplicate(),"swap_pending":swap_pending,"swap_enabled":swap_enabled,"win_lines":win_lines.duplicate(true),"result_recorded":result_recorded}
func restore(s: Dictionary) -> void:
	cells = s.cells.map(func(c): return int(c))
	last_cell = int(s.get("last_cell",-1))
	starter_owner = int(s.get("starter_owner",0))
	turn = int(s.turn)
	winner = int(s.winner)
	owners = s.owners.map(func(c): return int(c))
	swap_pending = s.swap_pending
	swap_enabled = s.swap_enabled
	win_lines = s.win_lines.map(func(line): return line.map(func(c): return int(c)))
	result_recorded = s.get("result_recorded",false)
func move_count() -> int:
	return 54-cells.count(0)
func current_owner() -> int:
	return owners[turn-1]
