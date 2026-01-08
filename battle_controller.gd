extends Node3D

@export var HexTile: PackedScene
var mapTiles: Array = [[0, 0, "default"], [0, 1, "default"], [1, 0, "default"], [1, 1, "default"]]

func _ready() -> void:
	for coordinate in mapTiles:
		print(coordinate)
		var newTile = HexTile.instantiate()
		newTile.id = 1
		add_child(newTile)
		newTile.initialize(Vector2(coordinate[0], coordinate[1]), coordinate[2])
	pass
