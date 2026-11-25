extends RefCounted

# Established 4x4 surface topology fitted to the existing Tower cube.
const SIDE: int = 4
const CELLS: int = 96
const STEP: float = 0.75
static var _lines: Array = []

static func face(cell: int) -> int:
    return floori(float(cell) / 16.0)

static func center(cell: int, height: float = 1.5) -> Vector3:
    var f: int = face(cell)
    var offset: int = cell % 16
    var row: int = floori(float(offset) / 4.0)
    var col: int = offset % 4
    return CubeGeometry.N[f] * height + CubeGeometry.U[f] * (float(col) - 1.5) * STEP + CubeGeometry.V[f] * (float(row) - 1.5) * STEP

static func edge_point(a: int, b: int) -> Vector3:
    var fa: int = face(a)
    var fb: int = face(b)
    var tangent: Vector3 = CubeGeometry.N[fa].cross(CubeGeometry.N[fb])
    return (CubeGeometry.N[fa] + CubeGeometry.N[fb]) * 1.54 + tangent * center(a).dot(tangent)

static func boundary(f: int, neighbor: int, tangent: Vector3, lane: int, inward: int) -> int:
    var near: float = 1.5 * STEP - float(inward) * STEP
    var along: float = -1.5 * STEP + float(lane) * STEP
    for cell in range(f * 16, f * 16 + 16):
        var point: Vector3 = center(cell, 0.0)
        if absf(point.dot(CubeGeometry.N[neighbor]) - near) < 0.001 and absf(point.dot(tangent) - along) < 0.001:
            return cell
    return -1

static func generate_lines() -> Array:
    if not _lines.is_empty():
        return _lines
    var result: Array = []
    for f in range(6):
        for row in range(4):
            var horizontal: Array = []
            var vertical: Array = []
            for col in range(4):
                horizontal.append(f * 16 + row * 4 + col)
                vertical.append(f * 16 + col * 4 + row)
            result.append(horizontal)
            result.append(vertical)
        result.append([f * 16, f * 16 + 5, f * 16 + 10, f * 16 + 15])
        result.append([f * 16 + 3, f * 16 + 6, f * 16 + 9, f * 16 + 12])
    for a in range(6):
        for b in range(a + 1, 6):
            if CubeGeometry.N[a].dot(CubeGeometry.N[b]) != 0.0:
                continue
            var tangent: Vector3 = CubeGeometry.N[a].cross(CubeGeometry.N[b])
            for lane in range(4):
                for split in range(1, 4):
                    var line: Array = []
                    for k in range(split - 1, -1, -1):
                        line.append(boundary(a, b, tangent, lane, k))
                    for k in range(4 - split):
                        line.append(boundary(b, a, tangent, lane, k))
                    if not line.has(-1):
                        result.append(line)
    _lines = result
    return _lines
