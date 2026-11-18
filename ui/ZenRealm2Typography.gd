extends RefCounted
## ZenCube 2.0 Realm typography: a clear display / UI hierarchy.
## Uses platform fonts; no unlicensed or bundled font asset.
static func body() -> Font:
    var face := SystemFont.new()
    face.font_names = PackedStringArray(["Noto Sans", "Roboto", "DejaVu Sans", "sans-serif"])
    return face

static func heading() -> Font:
    var face := SystemFont.new()
    face.font_names = PackedStringArray(["Noto Serif", "Droid Serif", "DejaVu Serif", "serif"])
    return face
