class_name WinLineGenerator
extends RefCounted
# Four connected surface cells; face orientations are handled by CubeGeometry.
# For each of 12 physical edges and 3 lanes: A3+B1, A2+B2, A1+B3.
static func generate() -> Array:
    var lines: Array = []
    for edge in CubeGeometry.edges():
        var a: int = edge[0]
        var b: int = edge[1]
        for lane in range(-1, 2):
            var a2: int = CubeGeometry.boundary(a,b,lane,2)
            var a1: int = CubeGeometry.boundary(a,b,lane,1)
            var a0: int = CubeGeometry.boundary(a,b,lane)
            var b0: int = CubeGeometry.boundary(b,a,-lane)
            var b1: int = CubeGeometry.boundary(b,a,-lane,1)
            var b2: int = CubeGeometry.boundary(b,a,-lane,2)
            assert(a2 >= 0 and a1 >= 0 and a0 >= 0 and b0 >= 0 and b1 >= 0 and b2 >= 0)
            lines.append([a2,a1,a0,b0])  # 3+1
            lines.append([a1,a0,b0,b1])  # 2+2
            lines.append([a0,b0,b1,b2])  # 1+3
    assert(lines.size() == 108)
    return lines
