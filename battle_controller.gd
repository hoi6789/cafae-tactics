extends Node3D

@export var HexTile: PackedScene
var mapTiles: Array = [[], [], []]

func _ready() -> void:
	var newTile = HexTile.instantiate()
	newTile.id = 1
	add_child(newTile)
	newTile.position = Vector3(1, 0, 0) 
	pass
