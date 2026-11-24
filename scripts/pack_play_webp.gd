extends SceneTree
## Build-only step for Godot 4.5.1. Reuse the original WebP stream when it
## decodes to exactly the same texture bytes in this engine as its import.
const HEADER_SIZE := 56
var saved_bytes := 0
var checked := 0
var packed := 0
var failed := false

func _initialize() -> void:
    for folder in ["res://assets", "res://story"]:
        inspect_directory(folder)
    print("Compared WebP imports: %d; compacted: %d; bytes saved: %d" % [checked, packed, saved_bytes])
    quit(1 if failed else 0)

func inspect_directory(path: String) -> void:
    for subdir in DirAccess.get_directories_at(path):
        inspect_directory(path.path_join(subdir))
    for filename in DirAccess.get_files_at(path):
        if filename.ends_with(".webp"):
            pack_if_identical(path.path_join(filename))

func pack_if_identical(source: String) -> void:
    var mapping := ConfigFile.new()
    if mapping.load(source + ".import") != OK:
        push_error("Missing texture import: " + source)
        failed = true
        return
    var target: String = mapping.get_value("remap", "path", "")
    if not target.begins_with("res://.godot/imported/") or not target.ends_with(".ctex"):
        return
    var imported := FileAccess.get_file_as_bytes(target)
    var original := FileAccess.get_file_as_bytes(source)
    checked += 1
    if imported.size() <= HEADER_SIZE or imported.slice(0, 4).get_string_from_ascii() != "GST2":
        return
    # Version 1, one WebP image, no mipmaps, no extra payload.
    if imported.decode_u32(4) != 1 or imported.decode_u32(36) != 2 or imported.decode_u32(44) != 0:
        return
    if imported.decode_u32(52) != imported.size() - HEADER_SIZE or original.size() >= imported.size() - HEADER_SIZE:
        return
    var current := Image.new()
    var replacement := Image.new()
    if current.load_webp_from_buffer(imported.slice(HEADER_SIZE)) != OK or replacement.load_webp_from_buffer(original) != OK:
        push_error("WebP decoder failed: " + source)
        failed = true
        return
    if current.get_size() != replacement.get_size():
        return
    var fmt := imported.decode_u32(48)
    if fmt not in [Image.FORMAT_RGB8, Image.FORMAT_RGBA8]:
        return
    current.convert(fmt)
    replacement.convert(fmt)
    if current.get_data() != replacement.get_data():
        return
    var header := imported.slice(0, HEADER_SIZE)
    header.encode_u32(52, original.size())
    var tmp := target + ".zencube-tmp"
    var f := FileAccess.open(tmp, FileAccess.WRITE)
    if f == null or not f.store_buffer(header) or not f.store_buffer(original):
        push_error("Cannot write compact import: " + source)
        failed = true
        return
    f.close()
    if DirAccess.rename_absolute(tmp, target) != OK:
        push_error("Cannot replace build cache: " + source)
        failed = true
        return
    packed += 1
    saved_bytes += imported.size() - HEADER_SIZE - original.size()
    print("MATCH\t%s\t%d\t%d" % [source, imported.size(), HEADER_SIZE + original.size()])
