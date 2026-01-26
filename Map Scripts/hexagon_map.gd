class_name HexagonMap

var map: Dictionary[Vector2, Hex] = {}

func _init(_map: Dictionary[Vector2, Hex] = {}):
	map = _map

func get_hex(Vector2 cubePos)
