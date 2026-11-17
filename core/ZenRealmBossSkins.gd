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
    {"name":"Wind Scribe", "core":"#315768", "faces":["#bde8e8","#8ec7cf","#accfd7","#a3dee4","#bbebef","#94c8da"],"metal":0.40,"rough":0.40},
    {"name":"Bridge Sentinel", "core":"#243e63", "faces":["#719ec8","#9cb8d7","#85b2d6","#a5c6e6","#7eb0db","#bbd3ea"],"metal":0.57,"rough":0.32},
    {"name":"Archivist of the Sky", "core":"#374962", "faces":["#e1dcc7","#c3d7ee","#d6e4eb","#e4ebd4","#bcd9e5","#d5d3c1"],"metal":0.48,"rough":0.36},
    {"name":"Lotus Witness", "core":"#5c3e5a", "faces":["#f0cdda","#deb9d9","#ecc5d5","#efd3db","#c7a6cb","#e9c4c3"],"metal":0.24,"rough":0.49},
    {"name":"Keeper of the Halo", "core":"#604e6c", "faces":["#d5bcf0","#f1d7bd","#cdb8e0","#efd9e4","#c9d1f3","#e4c2d4"],"metal":0.50,"rough":0.36},
    {"name":"The Fully Aware", "core":"#6e6050", "faces":["#f7f4e5","#e8d9b9","#f2e8d5","#d9d3e4","#f5e7cb","#faf5e9"],"metal":0.62,"rough":0.28},
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
            elif id == 5:
                base = Color("#322a30").lerp(Color("#7d4033"),0.2 + grain*0.18)
                var magma: float = absf(sin(u*33.0 + sin(v*12.0)*4.0))
                var cross: float = absf(sin(v*31.0 - sin(u*10.0)*3.0))
                if magma < 0.105 or cross < 0.065:
                    base = ember.lerp(gold,grain*0.43)
                if absf(u-0.5) < 0.019 and absf(v-0.5) < 0.3: base = gold
            elif id == 6: # Wind-written jade, long silver calligraphy strokes
                base = Color("#9dcbd4").lerp(Color("#def5ee"),0.3+grain*0.12)
                var wind_line: float = absf(sin((u+v*0.47)*19.0+sin(v*8.0)*2.7))
                if wind_line < 0.15: base = Color("#f2ffff")
                if absf(u-v) < 0.022: base = Color("#6aa6c4")
            elif id == 7: # Armored azure bridge marble, rivets and sky lines
                base = Color("#709fc9").lerp(Color("#d7e6f2"),grain*0.21)
                if absf(fposmod(u*4.0,1.0)-0.5) < 0.018 or absf(fposmod(v*4.0,1.0)-0.5) < 0.018:
                    base = Color("#e8d7a6")
                if Vector2(fposmod(u*4.0,1.0)-0.5,fposmod(v*4.0,1.0)-0.5).length() < 0.075:
                    base = Color("#f6f1ce")
            elif id == 8: # Ivory celestial archive with constellation patterns
                base = Color("#d8dcd7").lerp(Color("#eaf4fb"),grain*0.19)
                var radius: float = Vector2(u-0.5,v-0.5).length()
                if absf(radius-0.32) < 0.012 or absf(radius-0.2) < 0.007:
                    base = Color("#d6b96d")
                if absf(sin((u-v*0.63)*24.0)) < 0.028:
                    base = Color("#8babc7")
            elif id == 9: # Satori lotus-stone, rose petal silhouettes
                base = Color("#e9cadb").lerp(Color("#f8e6e3"),grain*0.19)
                var offset: Vector2 = Vector2(u-0.5,v-0.5)
                var petal: float = absf(offset.x) + 0.48*absf(offset.y)
                if petal < 0.16 and absf(offset.y) > absf(offset.x)*0.75:
                    base = Color("#fef5db")
                if absf(Vector2(offset.x*1.2,offset.y).length()-0.34) < 0.008:
                    base = Color("#d8ac6f")
            elif id == 10: # Lavender halo circle in gold
                base = Color("#cfbbdf").lerp(Color("#f6e4db"),0.3+grain*0.16)
                var halo_radius: float = Vector2(u-0.5,v-0.5).length()
                if absf(halo_radius-0.33) < 0.019 or absf(halo_radius-0.22) < 0.009:
                    base = Color("#f3dd95")
                if absf(sin((u+v)*13.0)) < 0.04:
                    base = Color("#b3badd")
            else: # Fully Aware: serene pearl-white mandala
                base = Color("#f3eadb").lerp(Color("#ffffff"),0.35+grain*0.17)
                var p: Vector2 = Vector2(u-0.5,v-0.5)
                var r: float = p.length()
                if absf(r-0.24) < 0.011 or absf(r-0.37) < 0.011:
                    base = Color("#dbbd78")
                var six_rays: float = absf(sin(atan2(p.y,p.x)*6.0))
                if six_rays < 0.075 and r < 0.37:
                    base = Color("#dab96a")
            img.set_pixel(x,y,base)
    img.generate_mipmaps()
    return ImageTexture.create_from_image(img)
