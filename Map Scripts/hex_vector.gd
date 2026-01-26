class_name HexVector

var q: float
var r: float
var s: float

func _init(_q,_r,_s):
	q = _q
	r = _r
	s = _s

static func fromCubePos(cubePos: Vector2) -> HexVector:
	var _q = cubePos.x
	var _r = cubePos.y
	var _s = 0 - _q - _r
	return HexVector.new(_q,_r,_s)

static func toCubePos(hex_vector: HexVector) -> Vector2:
	return Vector2(hex_vector.q, hex_vector.r)
