class_name CubeGeometry
extends RefCounted
# Local U points right; V points down when viewing a face from outside.
const N = [Vector3(0,0,1),Vector3(0,0,-1),Vector3(-1,0,0),Vector3(1,0,0),Vector3(0,1,0),Vector3(0,-1,0)]
const U = [Vector3(1,0,0),Vector3(-1,0,0),Vector3(0,0,1),Vector3(0,0,-1),Vector3(1,0,0),Vector3(1,0,0)]
const V = [Vector3(0,-1,0),Vector3(0,-1,0),Vector3(0,-1,0),Vector3(0,-1,0),Vector3(0,0,1),Vector3(0,0,-1)]
const NAMES = ["Vorne","Hinten","Links","Rechts","Oben","Unten"]
static func id(face: int, row: int, col: int) -> int:
	return face * 9 + row * 3 + col
static func face(cell: int) -> int:
	return cell / 9
static func center(cell: int, height: float = 1.5) -> Vector3:
	var f = face(cell)
	return N[f]*height + U[f]*(cell%3-1) + V[f]*((cell%9)/3-1)
static func edges() -> Array:
	var result = []
	for a in range(6):
		for b in range(a+1,6):
			if N[a].dot(N[b]) == 0: result.append([a,b])
	return result
static func boundary(f: int, neighbor: int, lane: int, inward: int = 0) -> int:
	var tangent = N[f].cross(N[neighbor])
	for c in range(f*9,f*9+9):
		var p = center(c)
		if is_equal_approx(p.dot(N[neighbor]),1.0-inward) and is_equal_approx(p.dot(tangent),float(lane)):
			return c
	return -1
static func edge_point(a: int, b: int) -> Vector3:
	var fa = face(a)
	var fb = face(b)
	var t = N[fa].cross(N[fb])
	return (N[fa]+N[fb])*1.54 + t*center(a).dot(t)
