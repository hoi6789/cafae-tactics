class_name HexTile

const JUMP_COST = 4
const JUMP_COST_MOD = 0
const JUMP_COST_BIAS = 0#0.5

var id = 0
var data_index = 0

## coordinates of the hex in cube space (q + r + s = 0)
var hex_pos: HexVector
var height: int = 0
var name: String = "Null"
 
var hex: Hex
enum TerrainType
{
	BASIC,
	ROUGH
}
var type: TerrainType = TerrainType.BASIC

func _init(_id: int, _pos: HexVector, _height: int, _type: TerrainType, _hex: Hex = null, _name: String = "Null"):
	type = _type
	hex_pos = _pos
	height = _height
	id = _id
	hex = _hex
	name = _name

func clone() -> HexTile:
	var cl = HexTile.new(id, hex_pos, height, type, hex, name)
	cl.data_index = data_index
	return cl

static func getTileTypeMovementCost(_type: HexTile.TerrainType) -> int:
	match _type:
		HexTile.TerrainType.BASIC: return 1
		HexTile.TerrainType.ROUGH: return 2
		_: return 1
	return 0

func getMovementCost() -> float:
	return getTileTypeMovementCost(type)

static func getHeightDifference(a: HexTile , b: HexTile):
	return abs(a.height - b.height)
