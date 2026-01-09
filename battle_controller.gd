extends Node3D

@export var HexTile: PackedScene
var mapTiles: Array = [[0, 0], [0, 1], [1, 0], [1, 1]]
var mapHexes: Array[Hex]

func _ready() -> void:
	for coordinate in mapTiles:
		print(coordinate)
		var newTile: Hex = HexTile.instantiate()
		newTile.id = 1
		add_child(newTile)
		if coordinate.size() == 2:
			newTile.initialize(Vector2(coordinate[0], coordinate[1]))
		elif coordinate.size() == 3: 
			newTile.initialize(Vector2(coordinate[0], coordinate[1]), coordinate[2])
		newTile.inputManager = %InputManager
		mapHexes.push_back(newTile)
	pass

func processInput(command: Array[int]):
	## Big function that runs the entire game. this is gonna be a big match case i'm so sorry
	match command[0]:
		
		_:
			print(mapHexes[0].id)
			
			pass
	pass
