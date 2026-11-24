extends RefCounted
## Shared Campaign 2.0 final guardian rules. Do not modify archive or ordinary 4x4.
## Medium, Hard (medium-high target), Master, Hard, Grandmaster.
const REALM_LEVELS: Array[int] = [1,2,3,2,4]
const WINS_REQUIRED := 2
const FINAL_BOSS := 2

static func defaults() -> Dictionary:
    return {"player":0,"guardian":0,"counted_attempt":0}

static func clean(raw: Variant) -> Dictionary:
    if not raw is Dictionary: return defaults()
    var human: int = clampi(int(raw.get("player",0)),0,WINS_REQUIRED)
    var bot: int = clampi(int(raw.get("guardian",0)),0,WINS_REQUIRED)
    if human==WINS_REQUIRED and bot==WINS_REQUIRED: return defaults()
    return {"player":human,"guardian":bot,"counted_attempt":maxi(0,int(raw.get("counted_attempt",0)))}

static func score(progress: Dictionary) -> Dictionary:
    return clean(progress.get("final_series",{}))

static func settle(progress: Dictionary) -> void:
    var game: Dictionary = progress.get("game",{})
    if int(game.get("boss",-1))!=FINAL_BOSS: return
    var outcome: int = int(game.get("result",0))
    if outcome not in [1,2,3]: return
    var tally: Dictionary = score(progress)
    var attempts: Array = progress.get("attempts",[0,0,0])
    if attempts.size()!=3: return
    var attempt: int = maxi(1,int(attempts[FINAL_BOSS]))
    # Migrate an unfinished legacy final board; its first result counts once.
    if int(attempts[FINAL_BOSS])<1:
        attempts[FINAL_BOSS] = 1
        progress.attempts = attempts
    if int(tally.counted_attempt)>=attempt: return
    if int(tally.player)>=WINS_REQUIRED or int(tally.guardian)>=WINS_REQUIRED: return
    if outcome==1: tally.player = int(tally.player)+1
    elif outcome==2: tally.guardian = int(tally.guardian)+1
    tally.counted_attempt = attempt
    progress.final_series = tally

static func player_won(progress: Dictionary) -> bool:
    return int(score(progress).player)>=WINS_REQUIRED

static func guardian_won(progress: Dictionary) -> bool:
    return int(score(progress).guardian)>=WINS_REQUIRED

static func start_next(progress: Dictionary) -> bool:
    var game: Dictionary = progress.get("game",{})
    if int(game.get("boss",-1))!=FINAL_BOSS or int(game.get("result",0)) not in [1,2,3]: return false
    settle(progress)
    if player_won(progress): return false
    if guardian_won(progress):
        var tally: Dictionary = score(progress)
        # Keep the monotonic round identifier across series restarts.
        progress.final_series = {"player":0,"guardian":0,"counted_attempt":int(tally.counted_attempt)}
    progress.game = {}
    return true

# The first mover is not the same as the current turn on a resumed board.
# Old saves have no starter field: reconstruct it from marks and the next turn.
static func round_starter(game: Dictionary) -> int:
    var stored: int = int(game.get("starter",0))
    if stored in [1,2]: return stored
    var marks: Array = game.get("cells",[])
    var x: int = marks.count(1)
    var o: int = marks.count(2)
    if x>o: return 1
    if o>x: return 2
    var current: int = clampi(int(game.get("turn",1)),1,2)
    return 3-current if int(game.get("result",0)) in [1,2,3] and x+o>0 else current

static func text_score(progress: Dictionary) -> String:
    var tally: Dictionary = score(progress)
    return "Best of 3 · Kuze %d : %d Guardian" % [int(tally.player),int(tally.guardian)]
