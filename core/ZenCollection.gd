class_name ZenCollection
extends RefCounted
# Index stability protects already-owned 9.5 skins; their MATERIALS are visual only.
const MATERIALS = ["Putz", "Kirschholz", "Bambusfasern", "Sandstein", "Glasur", "Jade", "Mondstein", "Gebürstetes Kupfer", "Marmoradern", "Klarglas", "Bernstein", "Kristall", "Korallenstein", "Smaragd", "Eis", "Lavastein", "Obsidian", "Gebürstetes Gold", "Irisierendes Glas", "Himmelsgold"]
# Earned-only in-game currency, no accounts or purchases.
# Each skin is a real 3D palette/material preset; the board geometry never changes.
const BOT_REWARDS = [8, 15, 25, 40, 65]
const CHALLENGE_REWARDS = [6, 10, 15, 25, 40]
const MUSIC_PRICES: Dictionary = {5: 120, 6: 180}
const SKINS = [
    {"name":"Klassischer Zen", "price":0, "faces":["c0b69a", "c0b69a", "74805b", "b68165", "e8d0ab", "d8b995"], "core":"6a5240", "x":"453329", "o":"16515a", "metal":0.03, "rough":0.78},
    {"name":"Kirschholz", "price":70, "faces":["c7a48d", "d3ad96", "b37d69", "bc8a78", "e0b89c", "c99980"], "core":"593b34", "x":"52312a", "o":"174d54", "metal":0.04, "rough":0.75},
    {"name":"Bambus", "price":90, "faces":["c9d4a2", "c3cf8e", "869d67", "a4b984", "dbe4b0", "b6c98b"], "core":"4b5a3b", "x":"294131", "o":"254f55", "metal":0.02, "rough":0.80},
    {"name":"Sandstein", "price":110, "faces":["e6d5b7", "dbc7a5", "c4ad8a", "d0b89c", "eadbc2", "d4bc9a"], "core":"806a50", "x":"443229", "o":"1c5360", "metal":0.00, "rough":0.88},
    {"name":"Sakura", "price":135, "faces":["f3d1d6", "f0c4cf", "d9a4bc", "f2c6b6", "fce2dc", "ebbad2"], "core":"936674", "x":"53384a", "o":"1a5460", "metal":0.04, "rough":0.64},
    {"name":"Jade", "price":155, "faces":["a8d8bc", "88c7a0", "489a82", "8fc7b0", "cee8d2", "78b79b"], "core":"315f54", "x":"193d3d", "o":"173e59", "metal":0.14, "rough":0.55},
    {"name":"Mondstein", "price":180, "faces":["c7cadc", "aeb6d0", "8c9ab9", "b5bed2", "dee0e8", "a7b8cd"], "core":"596071", "x":"253b52", "o":"155563", "metal":0.12, "rough":0.44},
    {"name":"Kupfer", "price":205, "faces":["d9b59a", "c99e82", "a87559", "c58b6c", "e9c7ac", "bb8b71"], "core":"654637", "x":"3c2c2b", "o":"144a58", "metal":0.32, "rough":0.48},
    {"name":"Marmor", "price":230, "faces":["ebebe8", "dedfe2", "babfc7", "d1d4d7", "f6f4ee", "c9cbd0"], "core":"777a80", "x":"293645", "o":"15606b", "metal":0.07, "rough":0.28},
    {"name":"Ozean", "price":260, "faces":["a0d4d7", "72b8c9", "3c879e", "77b7bc", "d0e8e5", "539bb4"], "core":"285269", "x":"173b53", "o":"164850", "metal":0.10, "rough":0.42},
    {"name":"Bernstein", "price":295, "faces":["efd2a0", "e9b867", "ba8a4e", "dca360", "f3dba9", "c99454"], "core":"655038", "x":"533827", "o":"1d5365", "metal":0.25, "rough":0.42},
    {"name":"Amethyst", "price":325, "faces":["d6c2e3", "bda2d6", "8868a7", "bca4c9", "e4d5eb", "a68bbb"], "core":"514363", "x":"2d2853", "o":"18556a", "metal":0.20, "rough":0.42},
    {"name":"Koralle", "price":355, "faces":["f1c0b0", "e8a394", "bc766d", "d99a91", "f6d3bb", "ca887f"], "core":"6c4d49", "x":"4d3039", "o":"1f5059", "metal":0.08, "rough":0.60},
    {"name":"Smaragd", "price":395, "faces":["8bd6bb", "65b89d", "2e8c75", "60b596", "b8e5cc", "459b7b"], "core":"23554d", "x":"18383a", "o":"124654", "metal":0.23, "rough":0.37},
    {"name":"Frost", "price":435, "faces":["ddeafa", "bcd9ee", "87b8dc", "b0cfed", "f5f9fa", "94caea"], "core":"536c83", "x":"23354b", "o":"155163", "metal":0.18, "rough":0.34},
    {"name":"Lavastein", "price":475, "faces":["9b918a", "77716e", "654b45", "a45e48", "c4aba0", "785a50"], "core":"372b2c", "x":"f4e8d5", "o":"1d5865", "metal":0.08, "rough":0.90},
    {"name":"Mitternacht", "price":515, "faces":["5f6e88", "4a5876", "353e64", "566987", "7d8da1", "455370"], "core":"293347", "x":"f3e6cd", "o":"8bd1d0", "metal":0.24, "rough":0.41},
    {"name":"Lotusgold", "price":565, "faces":["f1dea6", "dfc77b", "bd984e", "d5b36c", "f7eac4", "c8ad65"], "core":"806039", "x":"514029", "o":"155463", "metal":0.50, "rough":0.31},
    {"name":"Polarlicht", "price":615, "faces":["a5dfd1", "77cabb", "6b88bc", "9f7fc5", "c3dfe7", "7bbab9"], "core":"394f71", "x":"24364d", "o":"1a5264", "metal":0.30, "rough":0.34},
    {"name":"Himmelsgold", "price":690, "faces":["fff0ce", "ead8a7", "c7b37c", "eed3a1", "fff7e3", "dac39e"], "core":"7d693f", "x":"4b3c2e", "o":"17616a", "metal":0.58, "rough":0.26},
]

static func ensure(data: Dictionary) -> void:
    if not data.get("economy") is Dictionary: data["economy"] = {}
    var wallet: Dictionary = data["economy"]
    wallet["leaves"] = clampi(int(wallet.get("leaves", 0)), 0, 100000000)
    var owned_raw: Variant = wallet.get("owned", [0])
    var owned: Array = [0]
    if owned_raw is Array:
        for value in owned_raw:
            var skin: int = int(value)
            if skin >= 0 and skin < SKINS.size() and not owned.has(skin): owned.append(skin)
    owned.sort()
    wallet["owned"] = owned
    var selected: int = int(wallet.get("equipped", 0))
    wallet["equipped"] = selected if owned.has(selected) else 0
    wallet["migrated"] = bool(wallet.get("migrated", false))
    var music_raw: Variant = wallet.get("owned_music", [])
    var music_owned: Array = []
    if music_raw is Array:
        for value in music_raw:
            var track: int = int(value)
            if track in [5, 6] and not music_owned.has(track): music_owned.append(track)
    music_owned.sort()
    wallet["owned_music"] = music_owned

static func reward_bot(data: Dictionary, difficulty: int) -> int:
    ensure(data)
    if difficulty < 0 or difficulty >= BOT_REWARDS.size(): return 0
    var amount: int = BOT_REWARDS[difficulty]
    data.economy.leaves += amount
    return amount

static func reward_challenge(data: Dictionary, puzzle_level: int) -> int:
    ensure(data)
    if puzzle_level < 1 or puzzle_level > CHALLENGE_REWARDS.size(): return 0
    var amount: int = CHALLENGE_REWARDS[puzzle_level-1]
    data.economy.leaves += amount
    return amount

static func migrate_previous_rewards(data: Dictionary, solved: Dictionary) -> int:
    ensure(data)
    if bool(data.economy.migrated): return 0
    var total: int = 0
    var wins: Variant = data.get("stats", {}).get("ai_wins", [])
    if wins is Array:
        for i in range(mini(wins.size(), 5)):
            total += maxi(0, int(wins[i])) * BOT_REWARDS[i]
    for key in solved.keys():
        var puzzle_id: int = int(key)
        if puzzle_id >= 1 and puzzle_id <= 100 and bool(solved[key]):
            total += CHALLENGE_REWARDS[int((puzzle_id-1) / 20)]
    data.economy.leaves = mini(100000000, int(data.economy.leaves) + total)
    data.economy.migrated = true
    return total

static func buy(data: Dictionary, skin: int) -> bool:
    ensure(data)
    if skin < 1 or skin >= SKINS.size() or data.economy.owned.has(skin): return false
    var price: int = int(SKINS[skin].price)
    if price <= 0 or int(data.economy.leaves) < price: return false
    data.economy.leaves -= price
    data.economy.owned.append(skin)
    data.economy.owned.sort()
    return true

static func equip(data: Dictionary, skin: int) -> bool:
    ensure(data)
    if skin < 0 or skin >= SKINS.size() or not data.economy.owned.has(skin): return false
    data.economy.equipped = skin
    return true

# Base soundtrack (0..4) is free. Only bonus tracks 5 and 6 cost earned leaves.
static func music_price(track: int) -> int:
    return int(MUSIC_PRICES.get(track, 0))

static func music_unlocked(data: Dictionary, track: int) -> bool:
    ensure(data)
    if track >= 0 and track <= 4: return true
    return track in [5, 6] and data.economy.owned_music.has(track)

static func buy_music(data: Dictionary, track: int) -> bool:
    ensure(data)
    if not track in [5, 6] or data.economy.owned_music.has(track): return false
    var price: int = music_price(track)
    if price <= 0 or int(data.economy.leaves) < price: return false
    data.economy.leaves -= price
    data.economy.owned_music.append(track)
    data.economy.owned_music.sort()
    return true
