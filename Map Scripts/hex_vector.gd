class_name HexVector

var q: float
var r: float
var s: float

static var UNIT_Q: HexVector = HexVector.new(0, -1, 1)
static var UNIT_QR: HexVector = HexVector.new(1, -1, 0)
static var UNIT_R: HexVector = HexVector.new(1, 0, -1)
static var UNIT_RS: HexVector = HexVector.new(0, 1, -1)
static var UNIT_S: HexVector = HexVector.new(-1, 1, 0)
static var UNIT_QS: HexVector = HexVector.new(-1, 0, 1)
static var DIRECTIONS = [UNIT_Q,UNIT_QR,UNIT_R,UNIT_RS,UNIT_S,UNIT_QS]


func _init(_q,_r,_s):
	q = _q
	r = _r
	s = _s

func copy() -> HexVector:
	return HexVector.new(q, r, s)

static func fromCubePos(cubePos: Vector2) -> HexVector:
	var _q = cubePos.x
	var _r = cubePos.y
	var _s = 0 - _q - _r
	return HexVector.new(_q,_r,_s)

static func toCubePos(hex_vector: HexVector) -> Vector2:
	return Vector2(hex_vector.q, hex_vector.r)

static func lerp(a: HexVector, b: HexVector, t: float):
	return add(a, mult(sub(b, a), t))

static func _equals(a: HexVector, b: HexVector):
	return (a.q == b.q) and (a.r == b.r) and (a.s == b.s)
	
func equals(b: HexVector):
	return _equals(self, b)

static func add(a: HexVector, b: HexVector) -> HexVector:
	return HexVector.new(a.q+b.q,a.r+b.r,a.s+b.s)
	
static func mult(a: HexVector, c: float) -> HexVector:
	return HexVector.new(a.q*c,a.r*c,a.s*c)

static func sub(a: HexVector, b: HexVector) -> HexVector:
	return add(a,mult(b,-1))

static func dist(a: HexVector, b: HexVector) -> float:
	return (toCubePos(a) - toCubePos(b)).length()
