extends Node3D
class_name BattleController

## Enum used as a command list
enum Command {
	SUMMON_ENTITY,
	SUMMON_UNIT,
	SCRIPT
}

## Prefabs used for copying 
@export var LocHexTile: PackedScene
@export var SceneUnit: PackedScene
@export var hexData: HexData
@export var entityData: FieldEntityAtlas
@export_multiline var mapString: String

signal projectilesGone

static var playerTeam = 1
static var teams = 10

## Map variables
var map: HexagonMap = HexagonMap.new()


var highlightedPath: Array = []
var highlightedRange: Array = []
var scriptAtlas: ScriptAtlas
var units: Array[BattleUnit] = []
var entities: Array[FieldEntity] = []
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
	
	var chunk_size: int = int(ceil(0.01*(mapSize**2)))
	var tile_index = 0
	map.construct_using_string_form(mapString, hexData)
	for hex in map.map.values():
		map.spawn_hex(hex, LocHexTile, self).inputManager = %InputManager
		tile_index = (tile_index+1)%chunk_size
		if tile_index == 0:
			await get_tree().process_frame
	map.construct_entities_using_string_form(mapString, hexData, self)
	
	for i in range(teams):
		updateTeamSight(i)

	var ht = HexVector.fromCubePos(map.map.keys()[0])
	var h: HexTile = map.get_hex(ht)
	var hex = h.hex
	var n: Array[int] = [BattleController.Command.SUMMON_UNIT, hex.data.hex_pos.q, hex.data.hex_pos.r, hex.data.height, 1, -2, 2]
	InputManager.instance.addInput(n)

	#processInput([Command.SUMMON_UNIT, mapTiles[r][0], mapTiles[r][1], map.get_hex(HexVector.fromCubePos(Vector2(mapTiles[r][0],mapTiles[r][1]))).height, 1, 1, 0])

func getEntity(unitID: int) -> FieldEntity:
	return entities[unitID]

func getUnit(unitID: int) -> BattleUnit:
	return getEntity(unitID)

static func createEntity(command: Array[int], entityData: FieldEntityAtlas, unitID: int, map: HexagonMap, inputManager: InputManager) -> FieldEntity:
	var entity: FieldEntity = entityData.get_entity(command[1])
	
	entity.setLocation(HexVector.new(command[2],command[3],command[4]), command[5])
	
	entity.unitID = unitID
	entity.playerID = command[6]
	entity.teamID = command[7]
	entity.inputManager = inputManager
	
	var tile: HexTile = map.get_hex(entity.hex_pos)
	if tile != null:
		print("storing: ", tile.hex.name)
		tile.hex.storedEntities.push_back(entity)
	return entity

func processInput(command: Array[int]):
	## Big function that runs the entire game. this is gonna be a big match case i'm so sorry
	match command[0]:
		Command.SUMMON_ENTITY: ##summons an entity at a target hex. params: entity type id, q of hex, r of hex, h of hex tile, controller of unit, team of unit
			var entity: FieldEntity = createEntity(command, entityData, entities.size(), map, %InputManager)
			add_child(entity)
			entities.push_back(entity)
		Command.SUMMON_UNIT: ## summons a unit at a target hex. params: q of hex, r of hex, h of hex tile, id of unit, controller of unit, team of unit
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
			summonedUnit.unitID = entities.size()
			units.push_back(summonedUnit)
			entities.push_back(summonedUnit)
			var tile: HexTile = map.get_hex(HexVector.fromCubePos(Vector2(command[1],command[2])))
			tile.hex.storedEntities.push_back(summonedUnit)
			add_child(summonedUnit)
			updateTeamSight(summonedUnit.teamID)
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
	
	if teamID == playerTeam:
		for tile: HexTile in teamSightTiles[teamID]:
			if tile == null:
				continue
			tile.hex.setSight(false)
	
	teamSightTiles[teamID] = await getTeamSight(teamID)
	
	if teamID == playerTeam:
		for tile: HexTile in teamSightTiles[teamID]:
			if tile == null:
				continue
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
