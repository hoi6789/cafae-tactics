extends Node3D

@export var HexTile: PackedScene
var mapTiles: Array = [[0, 0], [0, 1], [1, 0], [1, 1]]

func _ready() -> void:
	for coordinate in mapTiles:
		print(coordinate)
		var newTile = HexTile.instantiate()
		newTile.id = 1
		add_child(newTile)
		newTile.setPosition(Vector2(coordinate[0], coordinate[1]))
	pass
