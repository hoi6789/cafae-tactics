extends Node3D
class_name BattleController

## Enum used as a command list
enum Command {
	SUMMON,
	MOVE,
	ATTACK,
}

## Prefabs used for copying 
@export var HexTile: PackedScene
@export var SceneUnit: PackedScene

var mapTiles: Array = [[0, 0], [0, 1], [1, 0], [1, 1]]
var mapHexes: Dictionary[String, Hex]
var mapHexesQ: Dictionary[int, Dictionary]
var mapHexesR: Dictionary[int, Dictionary]

func _ready() -> void:
	for coordinate in mapTiles:
		createTile(coordinate)
	pass
	processInput([Command.SUMMON, 0, 0, 1])

func createTile(coordinate):
	print(coordinate)
	var newTile: Hex = HexTile.instantiate()
	newTile.id = 1
	add_child(newTile)
	if coordinate.size() == 2:
		newTile.initialize(Vector2(coordinate[0], coordinate[1]))
	elif coordinate.size() == 3: 
		newTile.initialize(Vector2(coordinate[0], coordinate[1]), coordinate[2])
	newTile.inputManager = %InputManager
	mapHexes[str(coordinate[0]) + "," + str(coordinate[1])] = (newTile)
	if not mapHexesQ.has(coordinate[0]):
		mapHexesQ[coordinate[0]] = {}
	if not mapHexesR.has(coordinate[1]):
		mapHexesR[coordinate[1]] = {}
	mapHexesQ[coordinate[0]][coordinate[1]] = newTile
	mapHexesR[coordinate[1]][coordinate[0]] = newTile

func processInput(command: Array[int]):
	## Big function that runs the entire game. this is gonna be a big match case i'm so sorry
	match command[0]:
		Command.SUMMON: ## summons a unit at a target hex. params: q of hex, r of hex, id of unit, controller of unit, team of unit
			var summonedRes: Resource
			match command[3]:
				1: summonedRes = load("res://Unit Scripts/testUnit1.tres")
				_: summonedRes = load("res://Unit Scripts/testUnit1.tres")
			var summonedUnit = SceneUnit.instantiate()
			summonedUnit.inputManager = %InputManager
			summonedUnit.battleController = self
			summonedUnit.initialize(Vector2(command[1], command[2]), summonedRes)
			mapHexesQ[command[1]][command[2]].storedUnits.push_back(summonedUnit)
			add_child(summonedUnit)
			pass
		_:
			print(mapHexes["0,0"].id)
			print(mapHexesQ)
			print(mapHexesR)
			
			pass
	pass
