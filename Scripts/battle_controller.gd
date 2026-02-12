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

signal projectilesGone

static var playerTeam = 1

## Map variables
var map: HexagonMap = HexagonMap.new()

var mapTiles: Array = []
var highlightedPath: Array = []
var highlightedRange: Array = []
var scriptAtlas: ScriptAtlas
var units: Array[BattleUnit] = []
var projectiles: Array[Bullet] = []
var activeInputs = 0

var teamSightTiles: Dictionary[int, Array] = {}

func _ready() -> void:
	scriptAtlas = load("res://Resources/Script_Atlas.tres")
	scriptAtlas.init()
	seed(100)
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN # Set the noise type to Perlin
	noise.seed = randi() # Set a random or fixed seed
	var type_seed = randf()
	var height_seed = randf()
	noise.frequency = 0.05 # Control the scale/zoom of the noise
	noise.fractal_octaves = 5 # Add layers of noise for detail
	var mapSize = 20
	var scale: float = 4
	
	for i in range(-mapSize, mapSize):
		for j in range(-mapSize, mapSize):
			var hx = HexVector.fromCubePos(Vector2(i, j))
			var vx = HexMath.axis_to_3D(hx.q, hx.r)
			if noise.get_noise_2d(vx.x, vx.z) >-0.3:
				mapTiles.push_back([i, j, noise.get_noise_2d(height_seed + vx.x, height_seed + vx.z), noise.get_noise_2d(type_seed + vx.x, type_seed + vx.z)])
	var v2_arr = []
	for tile in mapTiles:
		v2_arr.push_back([tile[0], tile[1], tile[2], 2*abs(tile[3])])
	map.force_generate_with_terrain_types(v2_arr)
	
	var chunk_size: int = int(ceil(0.01*(mapSize**2)))
	var tile_index = 0
	for hextile: HexTile in map.hex_list.values():
		var cPos = HexVector.toCubePos(hextile.hex_pos)
		var coordinate = [cPos.x, cPos.y]
		
		var newTile: Hex = LocHexTile.instantiate()
		
		tile_index = (tile_index+1)%chunk_size
		if tile_index == 0:
			await get_tree().process_frame
		
		newTile.initialize(hextile)
		add_child(newTile)
		
		newTile.inputManager = %InputManager
	pass
	var r = randi_range(0, len(mapTiles))

	#processInput([Command.SUMMON, mapTiles[r][0], mapTiles[r][1], map.get_hex(HexVector.fromCubePos(Vector2(mapTiles[r][0],mapTiles[r][1]))).height, 1, 1, 0])

func getUnit(unitID: int) -> BattleUnit:
	return units[unitID]

func processInput(command: Array[int]):
	## Big function that runs the entire game. this is gonna be a big match case i'm so sorry
	match command[0]:
		Command.SUMMON: ## summons a unit at a target hex. params: q of hex, r of hex, h of hex tile, id of unit, controller of unit, team of unit
			var summonedRes: Resource
			match command[4]:
				1: summonedRes = load("res://Unit Scripts/testUnit1.tres")
				_: summonedRes = load("res://Unit Scripts/testUnit1.tres")
			var summonedUnit: BattleUnit = SceneUnit.instantiate()
			summonedUnit.inputManager = %InputManager
			summonedUnit.battleController = self
			summonedUnit.playerID = command[5]
			summonedUnit.teamID = command[6]
			summonedUnit.initialize(Vector2(command[1], command[2]), command[3], summonedRes, len(units))
			summonedUnit.unitID = units.size()
			units.push_back(summonedUnit)
			var tile: HexTile = map.get_hex(HexVector.fromCubePos(Vector2(command[1],command[2])))
			tile.hex.storedUnits.push_back(summonedUnit)
			add_child(summonedUnit)
			var r = randi_range(0, len(mapTiles))
			pass
		Command.SCRIPT:
			# [Command.SCRIPT, user, script id, data[0], data[1], data[2], ...]
			var script = inputToScript(command)
			print(Time.get_ticks_msec())
			await script.user.waitWindup(script.windup)
			await script.execute(self)
			await get_tree().create_timer(script.backswing).timeout
			pass
		_:
			pass
			
			pass
	activeInputs -= 1

func inputToScript(input) -> BattleScript:
	var script: BattleScript = scriptAtlas.get_move(input[2])
	script.user = getUnit(input[1])
	script.data = input.slice(3)
	return script 

func addProjectile(proj: Bullet):
	projectiles.push_back(proj)
	proj.controller = self
	add_child(proj)

func killProjectile(proj: Bullet):
	var ind: int = projectiles.find(proj)
	projectiles.pop_at(ind)
	proj.queue_free()
	if projectiles.size() == 0:
		projectilesGone.emit()

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

func highlightRange(hex_range: Array[HexTile]):
	unHighlightRange()
	for tile in hex_range:
		tile.hex.rangeHighlight()
		highlightedRange.push_back(tile)
		
func unHighlightRange():
	for tile in highlightedRange:
		tile.hex.unrangeHighlight()
	highlightedRange = []

func updateTeamSight(teamID: int):
	if teamID not in teamSightTiles:
		teamSightTiles[teamID] = []
	
	for tile: HexTile in teamSightTiles[teamID]:
		tile.hex.setSight(false)
	
	teamSightTiles[teamID] = await getTeamSight(teamID)
	
	for tile: HexTile in teamSightTiles[teamID]:
		tile.hex.setSight(true)

func getTeamSight(teamID: int) -> Array[HexTile]:
	var sightTiles: Array[HexTile]
	for unit in units:
		if unit.teamID == teamID:
			while unit._calculating_sight:
				await get_tree().process_frame
			for tile in unit.sight:
				if tile not in sightTiles:
					sightTiles.push_back(tile)
	return sightTiles
