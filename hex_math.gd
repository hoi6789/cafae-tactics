extends Node
class_name HexMath

## Global Offset is the gap between hexes, i.e. the side length of the hexagon
const GLOBAL_OFFSET = 0.5

## "Flat" Hexes lie flat from the default camera view perspective
## "Flat" and "Pointy" hexes will have different basis vectors
const FLAT_HEXES = false

static func axis_to_3D(q: float, r: float) -> Vector3:
	## multiplies by q/r basis vectors to determine position of the hex in world coords
	## basis vectors vary based on flat_hexes
	if FLAT_HEXES:
		var offset_q = q * GLOBAL_OFFSET * Vector3(1.5, 0, sqrt(3)/2)
		var offset_r = r * GLOBAL_OFFSET * Vector3(0, 0, sqrt(3))
		return offset_q + offset_r
	else:
		var offset_q = q * GLOBAL_OFFSET * Vector3(sqrt(3), 0, 0)
		var offset_r = r * GLOBAL_OFFSET * Vector3(sqrt(3)/2, 0, 1.5)
		return offset_q + offset_r
