extends Node3D

@export var HexTile: PackedScene
var mapTiles: Array = [[0, 0, 0], [sqrt(3)/2, 0, 0], [0, 0, 2]]

func _ready() -> void:
	for coordinate in mapTiles:
		print(coordinate)
		var newTile = HexTile.instantiate()
		newTile.id = 1
		add_child(newTile)
		newTile.position = Vector3(coordinate[0], coordinate[1], coordinate[2])
	pass
