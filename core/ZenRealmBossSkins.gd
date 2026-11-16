extends RefCounted
## Six lightweight, procedural real 3D surface textures. Generated once, cached
## by AscendRenderer and applied to actual BoxMesh tile materials, NOT the backdrop.
## These IDs belong only to Realm Chronicles and never enter ZenCollection.SKINS.
const PROFILES: Array = [
    {"name":"Mist Guardian", "core":"#526879", "faces":["#a9bdc7","#8a9ead","#95aeb9","#a0b2c5","#9aabb8","#758a9c"],"metal":0.23,"rough":0.54},
    {"name":"Mirror Novice", "core":"#62738b", "faces":["#d0dae9","#adbfd0","#c0c8d8","#a1bed3","#b9bbd4","#9eafc9"],"metal":0.71,"rough":0.23},
    {"name":"Veil Monk", "core":"#1c233b", "faces":["#444b78","#29375c","#404773","#292f55","#484b77","#32365b"],"metal":0.42,"rough":0.42},
    {"name":"Ash Runner", "core":"#30292a", "faces":["#51423c","#433634","#57423b","#4a3736","#3e3030","#543e37"],"metal":0.11,"rough":0.82},
    {"name":"Banner Guardian", "core":"#3a2024", "faces":["#8c3838","#67262b","#983e3b","#702a31","#873536","#692a2d"],"metal":0.31,"rough":0.48},
    {"name":"High Priest of Embers", "core":"#271920", "faces":["#542d28","#442126","#643328","#3e2024","#5b2925","#3b2021"],"metal":0.46,"rough":0.46},
]
static func get_profile(index: int) -> Dictionary:
    return PROFILES[clampi(index,0,PROFILES.size()-1)]

static func make_surface(index: int) -> ImageTexture:
    # 160x160 RGBA8 is cheap on Android. All highlights are original
    # deterministic material markings: fog, facets, runes, fissures, banners.
    var id: int = clampi(index,0,PROFILES.size()-1)
    var img: Image = Image.create(160,160,false,Image.FORMAT_RGBA8)
    var ice := Color("#cedce7")
    var gold := Color("#e9bc77")
    var ember := Color("#ff8e36")
    for y in range(160):
        for x in range(160):
            var u: float = float(x)/159.0
            var v: float = float(y)/159.0
            var grain: float = float((x*113 + y*41 + id*193 + (x*y) % 97) % 101) / 101.0
            var base: Color = Color("#c6c9ca")
            if id == 0:
                var mist: float = sin(u*24.0 + sin(v*8.0)*4.0 + v*5.0)
                base = Color("#889ba8").lerp(ice,clampf(0.25+0.27*mist+grain*0.2,0.0,1.0))
            elif id == 1:
                var facet: int = (int(u*9.0) + int(v*7.0) + int(absf(u-v)*9.0)) % 4
                base = [Color("#b9becf"),Color("#e4edfa"),Color("#879ab3"),Color("#c2cce2")][facet]
                if fposmod((u+v)*7.0,1.0) < 0.018: base = ice
            elif id == 2:
                base = Color("#242947").lerp(Color("#6267a0"),0.22+0.1*grain)
                var radius: float = Vector2(u-0.5,v-0.5).length()
                if absf(radius-0.28) < 0.015 or absf(radius-0.39) < 0.009:
                    base = gold
                if absf(u-0.5) < 0.014 and v > 0.20 and v < 0.8: base = gold.darkened(0.15)
            elif id == 3:
                base = Color("#37383b").lerp(Color("#6a5347"),grain*0.24)
                var crack: float = absf(sin(u*27.0 + sin(v*18.0)*3.0))
                if crack < 0.09 or absf(sin(v*32.0 + u*7.0)) < 0.06:
                    base = ember.darkened(0.12 + 0.2*grain)
            elif id == 4:
                base = Color("#63272e").lerp(Color("#ac5647"),0.18 + grain*0.18)
                if fposmod(u*5.0,1.0) < 0.022 or absf(v-0.5) < 0.012: base = gold
                if absf(u-0.5) < 0.04 and absf(v-0.5) < 0.2: base = gold.darkened(0.3)
            else:
                base = Color("#322a30").lerp(Color("#7d4033"),0.2 + grain*0.18)
                var magma: float = absf(sin(u*33.0 + sin(v*12.0)*4.0))
                var cross: float = absf(sin(v*31.0 - sin(u*10.0)*3.0))
                if magma < 0.105 or cross < 0.065:
                    base = ember.lerp(gold,grain*0.43)
                if absf(u-0.5) < 0.019 and absf(v-0.5) < 0.3: base = gold
            img.set_pixel(x,y,base)
    img.generate_mipmaps()
    return ImageTexture.create_from_image(img)
