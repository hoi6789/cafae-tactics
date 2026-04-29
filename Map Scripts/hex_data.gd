class_name HexData
extends Resource

@export var data_list: Array[HexDataElement]


func fromDataElement(ele: HexDataElement, ind: int) -> HexTile:
	var newTile: HexTile = HexTile.new(0, HexVector.fromCubePos(Vector2(0, 0)), 0, ele.type, null, ele.name)
	newTile.data_index = ind
	return newTile

func get_data(ind: int) -> HexTile:
	return fromDataElement(data_list[ind], ind)
