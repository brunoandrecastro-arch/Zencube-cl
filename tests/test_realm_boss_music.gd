extends SceneTree
## Verify dedicated Boss music maps all twelve stages and remains safe when assets
## are pending; once uploaded, assert every OGG decodes and loops.
const BossMusic = preload("res://core/ZenRealmBossMusic.gd")
const Story = preload("res://story/ZenRealmChronicles.gd")
var failures: int = 0
func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        printerr("BOSS AUDIO FAIL: ",message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    check(BossMusic.BOSS_IDS.size() == 12, "12 boss IDs")
    check(BossMusic.TRACK_TITLES.size() == 12, "12 track titles")
    check(Story.BOSS_IDS.size() == 12, "12 stage identities")
    for stage in range(12):
        check(BossMusic.BOSS_IDS[stage] == Story.BOSS_IDS[stage], "stage mapping " + str(stage))
        check(BossMusic.title_for(stage).length() > 3, "music title " + str(stage))
        check(BossMusic.path_for(stage).ends_with("/" + Story.BOSS_IDS[stage] + ".ogg"), "music path " + str(stage))
        var music: AudioStream = BossMusic.stream_for(stage)
        if ResourceLoader.exists(BossMusic.path_for(stage)):
            check(music is AudioStreamOggVorbis,"decodes OGG " + str(stage))
            if music is AudioStreamOggVorbis:
                check((music as AudioStreamOggVorbis).loop,"loops OGG " + str(stage))
                check((music as AudioStreamOggVorbis).get_length() > 60.0,"full length soundtrack " + str(stage))
        else:
            # Do not ship a fake music-complete claim when binary assets have
            # not yet been uploaded. The game safely keeps its Realm music.
            print("BOSS AUDIO PENDING asset: ",BossMusic.path_for(stage))
            check(music == null, "missing audio safely falls back " + str(stage))
    print("BOSS AUDIO test failures: ",failures)
    quit(1 if failures != 0 else 0)
