extends Node3D
class_name BattleController

## Enum used as a command list
enum Command {
	SUMMON,
	SCRIPT
}

## Prefabs used for copying 
@export var LocHexTile: PackedScene
@export var SceneUnit: PackedScene

static var playerTeam = 1

## Map variables
var map: HexagonMap = HexagonMap.new()

var mapTiles: Array = []
var highlightedPath: Array
var scriptAtlas: ScriptAtlas
var units: Array[BattleUnit] = []
var activeInputs = 0

func _ready() -> void:
	scriptAtlas = load("res://Resources/Script_Atlas.tres")
	scriptAtlas.init()
	seed(100)
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN # Set the noise type to Perlin
	noise.seed = randi() # Set a random or fixed seed
	noise.frequency = 0.05 # Control the scale/zoom of the noise
	noise.fractal_octaves = 5 # Add layers of noise for detail
	var mapSize = 10
	var scale: float = 4
	
	for i in range(-mapSize, mapSize):
		for j in range(-mapSize, mapSize):
			var hx = HexVector.fromCubePos(Vector2(i, j))
			var vx = HexMath.axis_to_3D(hx.q, hx.r)
			if noise.get_noise_2d(vx.x, vx.z) < -0.05:
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
	var r = randi_range(0, len(mapTiles))
	processInput([Command.SUMMON, mapTiles[r][0], mapTiles[r][1], 1, 1, 0])

func getUnit(unitID: int) -> BattleUnit:
	return units[unitID]

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
			summonedUnit.playerID = command[4]
			summonedUnit.teamID = command[5]
			summonedUnit.initialize(Vector2(command[1], command[2]), summonedRes, len(units))
			summonedUnit.unitID = units.size()
			units.push_back(summonedUnit)
			var tile: HexTile = map.get_hex(HexVector.fromCubePos(Vector2(command[1],command[2])))
			tile.hex.storedUnits.push_back(summonedUnit)
			add_child(summonedUnit)
			var r = randi_range(0, len(mapTiles))
			pass
		Command.SCRIPT:
			# [Command.SCRIPT, user, script id, data[0], data[1], data[2], ...]
			var script: BattleScript = scriptAtlas.get_move(command[2])
			script.user = getUnit(command[1])
			script.data = command.slice(3)
			print(Time.get_ticks_msec())
			await script.user.waitWindup(script.windup)
			await script.execute(self)
			await get_tree().create_timer(script.backswing).timeout
			pass
		_:
			pass
			
			pass
	activeInputs -= 1

func removeHighlights():
	for tile in highlightedPath:
		tile.hex.unhighlight()
	highlightedPath = []

func highlightPath(hex_path: Array[HexTile]):
	for tile in highlightedPath:
		tile.hex.unhighlight()
	for tile: HexTile in hex_path:
		tile.hex.highlight()
	highlightedPath = hex_path
