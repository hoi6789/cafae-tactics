class_name HexTile

var id = 0

## coordinates of the hex in cube space (q + r + s = 0)
var hex_pos: HexVector 
var hex: Hex
enum TerrainType
{
	BASIC,
	ROUGH
}
var type: TerrainType = TerrainType.BASIC

func _init(_id: int, _pos: HexVector, _type: TerrainType, _hex: Hex = null):
	type = _type
	hex_pos = _pos
	id = _id
	hex = _hex

static func getTileTypeMovementCost(_type: HexTile.TerrainType) -> int:
	match _type:
		HexTile.TerrainType.BASIC: return 1
		HexTile.TerrainType.ROUGH: return 2
		_: return 1
	return 0

func getMovementCost() -> float:
	return getTileTypeMovementCost(type)
