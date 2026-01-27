class_name HexTile

var id = 0

## coordinates of the hex in cube space (q + r + s = 0)
var hex_pos: HexVector 
enum TerrainType
{
	BASIC
}
var type: TerrainType = TerrainType.BASIC

func _init(_id: int, _pos: HexVector, _type: TerrainType):
	type = _type
	hex_pos = _pos
	id = _id
