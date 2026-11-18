extends RefCounted
## Campaign 2.0 – four exclusive real 3D materials. Never adds Shop skin IDs.
## The reference artwork stays separate from these generated playable surfaces.
const PROFILES: Array = [
    {"name":"Abyss Main","core":"#193943","faces":["#376d70","#26616b","#457e7d","#2d727c","#448b83","#205562"],"metal":0.30,"rough":0.50},
    {"name":"Memory Thief","core":"#24213a","faces":["#7b79ab","#555c9a","#8c8cbd","#5d568f","#a4a7ca","#6862ad"],"metal":0.72,"rough":0.23},
    {"name":"Weeping Blade","core":"#202936","faces":["#96a7b9","#677b91","#b1bec9","#7e8caa","#b3bec6","#617f99"],"metal":0.67,"rough":0.34},
    {"name":"Forgotten Shogun","core":"#171b25","faces":["#49434b","#2c313c","#45404a","#363441","#55505b","#222735"],"metal":0.70,"rough":0.37}
]
static func get_profile(index: int) -> Dictionary:
    return PROFILES[clampi(index,0,PROFILES.size()-1)]

static func make_surface(index: int) -> ImageTexture:
    var id: int = clampi(index,0,3)
    var img: Image = Image.create(160,160,false,Image.FORMAT_RGBA8)
    var gold: Color = Color("#e3c28b")
    var pearl: Color = Color("#d6eef6")
    for y in range(160):
        for x in range(160):
            var u: float = float(x)/159.0
            var v: float = float(y)/159.0
            var grain: float = float((x*53 + y*97 + x*y + id*193)%97)/97.0
            var c: Color = Color("#4b8b8c")
            if id == 0:
                # Weathered submerged shrine stone, azure water glow and moss.
                c = Color("#275760").lerp(Color("#4a8e8f"),0.25+0.26*grain)
                var column: float = minf(absf(u-0.17),absf(u-0.83))
                if column < 0.032 and v > 0.22 and v < 0.88: c = Color("#7a9590")
                if absf(v-0.22) < 0.036 and u > 0.12 and u < 0.88: c = Color("#7a9590")
                if absf(u-0.5) < 0.012 and v > 0.34 and v < 0.8: c = Color("#74edf4")
                if absf(sin((u+v*0.6)*27.0)) < 0.035: c = c.lerp(pearl,0.33)
            elif id == 1:
                # Broken mirrors hold shifting silhouettes in lilac crystal.
                var tile: int = int(u*7.0 + v*2.0)%3 + int(v*6.0)%3
                c = [Color("#8c85ba"),Color("#494c76"),Color("#b3bad7"),Color("#6d6b9c"),Color("#9389c8")][tile%5]
                if absf(sin((u+v)*21.0+sin(v*9.0))) < 0.09: c = pearl
                if absf(sin((u-v)*19.0)) < 0.045: c = Color("#c5c8fa")
            elif id == 2:
                # Rain-frosted silver, cherry petals and fractured steel.
                c = Color("#69788e").lerp(Color("#c0cbd4"),0.25+0.24*grain)
                if absf(sin((u*1.3-v)*30.0+sin(v*11.0))) < 0.07: c = Color("#dceff5")
                var drop: Vector2 = Vector2(fposmod(u*9.0,1.0)-0.5,fposmod(v*8.0+u*3.0,1.0)-0.5)
                if drop.length() < 0.067: c = Color("#95b8d3")
                if Vector2(u-0.77,v-0.25).length() < 0.10: c = Color("#d8b6d3")
            else:
                # Obsidian shogun lamellar armor, rivets and fading gilt.
                c = Color("#252936").lerp(Color("#52515b"),grain*0.27)
                if absf(fposmod(v*5.0,1.0)-0.12) < 0.023: c = gold
                if absf(fposmod(u*4.0+v*0.6,1.0)-0.5) < 0.018: c = Color("#ad9476")
                var rivet: Vector2 = Vector2(fposmod(u*4.0+v*0.6,1.0)-0.5,fposmod(v*5.0,1.0)-0.22)
                if rivet.length() < 0.055: c = gold.lightened(0.21)
                if absf(sin(u*26.0+v*8.0)) < 0.015: c = c.lerp(Color("#d9bd90"),0.6)
            img.set_pixel(x,y,c)
    img.generate_mipmaps()
    return ImageTexture.create_from_image(img)
