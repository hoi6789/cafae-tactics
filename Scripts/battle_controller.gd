extends Node3D
class_name BattleController

## Enum used as a command list
enum Command {
	SUMMON,
	MOVE,
	ATTACK,
}

## Prefabs used for copying 
@export var LocHexTile: PackedScene
@export var SceneUnit: PackedScene

## Map variables
var map: HexagonMap = HexagonMap.new()

var mapTiles: Array = []

func _ready() -> void:
	for i in range(0, 2):
		for j in range(0, 2):
			mapTiles.push_back([i, j])
	var v2_arr = []
	for tile in mapTiles:
		v2_arr.push_back(Vector2(tile[0], tile[1]))
	map.force_generate(v2_arr)
	
	for hextile: HexTile in map.hex_list.values():
		var cPos = HexVector.toCubePos(hextile.hex_pos)
		var coordinate = [cPos.x, cPos.y]
		print(cPos)
		var newTile: Hex = LocHexTile.instantiate()
		newTile.initialize(hextile)
		add_child(newTile)
		
		newTile.inputManager = %InputManager
	pass
	processInput([Command.SUMMON, 0, 0, 1])

func processInput(command: Array[int]):
	## Big function that runs the entire game. this is gonna be a big match case i'm so sorry
	match command[0]:
		Command.SUMMON: ## summons a unit at a target hex. params: q of hex, r of hex, id of unit, controller of unit, team of unit
			var summonedRes: Resource
			match command[3]:
				1: summonedRes = load("res://Unit Scripts/testUnit1.tres")
				_: summonedRes = load("res://Unit Scripts/testUnit1.tres")
			var summonedUnit: BattleUnit = SceneUnit.instantiate()
			summonedUnit.inputManager = %InputManager
			summonedUnit.battleController = self
			summonedUnit.initialize(Vector2(command[1], command[2]), summonedRes)
			var tile: HexTile = map.get_hex(HexVector.fromCubePos(Vector2(command[1],command[2])))
			tile.hex.storedUnits.push_back(summonedUnit)
			add_child(summonedUnit)
			highlightPath(map.getShortestPath(map.get_hex(summonedUnit.hex_pos), map.get_hex(HexVector.fromCubePos(Vector2(mapTiles[-1][0],mapTiles[-1][1])))))
			pass
		_:
			pass
			
			pass
	pass

func highlightPath(hex_path: Array[HexTile]):
	for tile: HexTile in hex_path:
		tile.hex.highlight()
