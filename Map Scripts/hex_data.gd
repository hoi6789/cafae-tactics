class_name HexData
extends Resource

@export var data_list: Array[HexDataElement]


func fromDataElement(ele: HexDataElement) -> HexTile:
	return HexTile.new(0, HexVector.fromCubePos(Vector2(0, 0)), 0, ele.type)

func get_data(ind: int) -> HexTile:
	return fromDataElement(data_list[ind])
