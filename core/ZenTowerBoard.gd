extends BoardModel

func _init(side: int = 3) -> void:
    cells.resize(96 if side == 4 else 54)
    cells.fill(0)
    swap_enabled = false
    swap_pending = false

func move_count() -> int:
    return cells.size() - cells.count(0)
