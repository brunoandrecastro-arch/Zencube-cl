class_name ZenBackdrops
extends RefCounted
# Independent cosmetic backdrops. Never change Classic world, its bot, or ranks.
const ITEMS = [
    {"name":"Kirschgarten", "price":250, "path":"res://assets/shop_backdrops/sakura_garden.webp"},
    {"name":"Bergtempel-Kulisse", "price":350, "path":"res://assets/shop_backdrops/mountain_temple.webp"},
    {"name":"Mondgarten-Kulisse", "price":450, "path":"res://assets/shop_backdrops/moon_garden.webp"},
    {"name":"Himmelsgarten-Kulisse", "price":550, "path":"res://assets/shop_backdrops/sky_garden.webp"},
]

static func ensure(data: Dictionary) -> void:
    if not data.get("economy") is Dictionary:
        data["economy"] = {}
    var economy: Dictionary = data["economy"]
    var raw: Variant = economy.get("owned_backdrops", [])
    var owned: Array = []
    if raw is Array:
        for value in raw:
            var idx: int = int(value)
            if idx >= 0 and idx < ITEMS.size() and not owned.has(idx):
                owned.append(idx)
    economy["owned_backdrops"] = owned
    var chosen: int = int(economy.get("selected_backdrop", -1))
    economy["selected_backdrop"] = chosen if chosen == -1 or owned.has(chosen) else -1

static func selected(data: Dictionary) -> int:
    ensure(data)
    return int(data.economy.selected_backdrop)

static func is_owned(data: Dictionary, idx: int) -> bool:
    ensure(data)
    return idx >= 0 and idx < ITEMS.size() and data.economy.owned_backdrops.has(idx)

static func purchase(data: Dictionary, idx: int) -> bool:
    ensure(data)
    if idx < 0 or idx >= ITEMS.size(): return false
    if data.economy.owned_backdrops.has(idx): return true
    var price: int = int(ITEMS[idx].price)
    if int(data.economy.get("leaves", 0)) < price: return false
    data.economy.leaves = int(data.economy.leaves) - price
    data.economy.owned_backdrops.append(idx)
    return true

static func equip(data: Dictionary, idx: int) -> bool:
    ensure(data)
    if idx == -1:
        data.economy.selected_backdrop = -1
        return true
    if not is_owned(data, idx): return false
    data.economy.selected_backdrop = idx
    return true
