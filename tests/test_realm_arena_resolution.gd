extends SceneTree
const ArenaShader = preload("res://ui/RealmArenaBackdrop.gdshader")
const Celestial = preload("res://story/ZenCelestialCampaign.gd")
const Shadow = preload("res://story/ZenShadowCampaign.gd")
const Abyss = preload("res://story/ZenAbyssCampaign.gd")
const Ember = preload("res://story/ZenEmberCampaign.gd")

func _initialize() -> void:
    var ok: bool = ArenaShader != null
    for model in [Shadow,Abyss,Ember,Celestial]:
        for i in range(3):
            var path: String = model.ASSET_ROOT + "arenas/" + model.BOSS_IDS[i] + ".webp"
            var texture: Texture2D = model.battle_backdrop(i)
            if texture==null:
                push_error("No battle background: "+path)
                ok=false
                continue
            print(model.BOSS_IDS[i],": ",texture.resource_path," ",texture.get_width()," x ",texture.get_height())
            if model==Ember and not ResourceLoader.exists(path):
                print("Ember continues using existing realm art; no new arena substituted.")
                continue
            if texture.resource_path!=path:
                push_error("Unexpected arena fallback: "+path)
                ok=false
            if model==Celestial and (texture.get_width()!=3840 or texture.get_height()!=2160):
                push_error("Celestial 4K texture was resized: "+path)
                ok=false
    quit(0 if ok else 1)
