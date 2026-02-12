extends Node
class_name HexMath

## Global Offset is the gap between hexes, i.e. the side length of the hexagon
const GLOBAL_OFFSET = 0.5
static var q_base = GLOBAL_OFFSET * Vector3(sqrt(3), 0, 0)
static var r_base = GLOBAL_OFFSET * Vector3(sqrt(3)/2, 0, 1.5)

## "Flat" Hexes lie flat from the default camera view perspective
## "Flat" and "Pointy" hexes will have different basis vectors
const FLAT_HEXES = false

## Hex Height is the Y value of the hex.
const HEX_HEIGHT = 0.1

static func average(A: Array[HexVector]) -> HexVector:
	var sum: Vector3 = Vector3.ZERO
	for h in A:
		sum += axis_to_3D(h.q,h.r)
	return _3D_to_axis(sum/len(A))

static func _3D_to_axis(xy: Vector3) -> HexVector:
	return _2D_to_axis(Vector2(xy.x, xy.z))

static func _2D_to_axis(xy: Vector2) -> HexVector:
	var hex_basis: Basis = Basis(q_base, r_base,Vector3(0,1,0))
	var qr = hex_basis.inverse()*Vector3(xy.x,0,xy.y)
	return HexVector.new(qr.x, qr.y)

static func axis_to_3D(q: float, r: float) -> Vector3:
	## multiplies by q/r basis vectors to determine position of the hex in world coords
	## basis vectors vary based on flat_hexes
	if FLAT_HEXES:
		var offset_q = q * GLOBAL_OFFSET * Vector3(1.5, 0, sqrt(3)/2)
		var offset_r = r * GLOBAL_OFFSET * Vector3(0, 0, sqrt(3))
		return offset_q + offset_r
	else:
		var offset_q = q * q_base
		var offset_r = r * r_base
		return offset_q + offset_r

static func axis_to_2D(h: HexVector) -> Vector2:
	var v = axis_to_3D(h.q,h.r)
	return Vector2(v.x,v.z)
