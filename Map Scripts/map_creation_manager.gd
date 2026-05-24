class_name MapCreator
extends Node

static var singleton: MapCreator

@export var HexTilePrefab: PackedScene
@export var TileIconPrefab: PackedScene
@export var EntityIconPrefab: PackedScene
@export var tileGrid: GridContainer
@export var entityGrid: GridContainer
@export var data: HexData
@export var entityData: FieldEntityAtlas
@export var cam: Camera3D
@export var outputText: TextEdit

var lastMousePos: Vector2
var hex_inst #last known intersection between mouse raycast and height plane

var placementData: PlacementData
var inMenu = false

class GhostHex:	
	var ghost_hex: Hex
	var ghost_hex_pos: Vector2
	var ghost_hex_targ: Vector2
	
	func _init(activeHex: HexTile) -> void:
		ghost_hex = MapCreator.singleton.spawn_hex(MapCreator.singleton.data.get_data(0), -1, false)
		ghost_hex.collider.disabled = true
		ghost_hex_pos = HexVector.toCubePos(activeHex.hex_pos)
	
	func set_ghost_position(delta:float, cubePos: Vector2, height: int):
		ghost_hex.data.height = height
		ghost_hex_pos += 15*delta*(cubePos - ghost_hex_pos)
		ghost_hex.setPosition(ghost_hex_pos)
		

class PlacementData:
	
	enum SelectionMode {
		NONE,
		HEX,
		ENTITY
	}
	var current_placement_height: int = 0
	var current_hex: HexTile
	var current_hex_id: int = 0
	var current_entity_id: int = 0
	var ghost: GhostHex
	var selectionMode: SelectionMode = SelectionMode.NONE
	
	func _init() -> void:
		current_hex = MapCreator.singleton.data.get_data(0)
		ghost = GhostHex.new(current_hex)
	
	func set_type(id: int):
		current_hex_id = id
		var new_hex: HexTile = MapCreator.singleton.data.get_data(id)
		new_hex.height = current_hex.height
		new_hex.hex_pos = current_hex.hex_pos

		ghost.ghost_hex.initialize(new_hex.clone())
		
		current_hex = new_hex
	
	func set_entity_type(id: int):
		current_entity_id = id
	
	func update_parameters(delta: float, pos: HexVector, height: int = current_placement_height):
		current_hex.height = height
		current_hex.hex_pos = pos
		ghost.set_ghost_position(delta, HexVector.toCubePos(pos), height)
	
	func update_ghost_position(delta: float):
		ghost.set_ghost_position(delta, HexVector.toCubePos(current_hex.hex_pos), current_placement_height)
	
var hexmap: HexagonMap = HexagonMap.new()

var hextile_lookup: Dictionary[int, Hex]
var id_lookup: Dictionary[Vector2, int]

var MAX_HEX_ID = 0

func get_plane_pos():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = cam.project_ray_origin(mouse_pos)
	var ray_dir = cam.project_ray_normal(mouse_pos)
	#calculate plane intersection
	var hex_plane = Plane(Vector3.UP, placementData.current_placement_height*Hex.TILE_HEIGHT)
	var h_i = hex_plane.intersects_ray(ray_origin, ray_dir)
	
	if h_i != null:
		var plane_pos = Vector2(h_i.x, h_i.z)
		var plane_hex: HexVector = HexMath._2D_to_axis(plane_pos)
		
		var roundedVectors = [
			HexVector.new(ceil(plane_hex.q), ceil(plane_hex.r), ceil(plane_hex.s)),
			HexVector.new(floor(plane_hex.q), ceil(plane_hex.r), ceil(plane_hex.s)),
			HexVector.new(ceil(plane_hex.q), floor(plane_hex.r), ceil(plane_hex.s)),
			HexVector.new(ceil(plane_hex.q), ceil(plane_hex.r), floor(plane_hex.s)),
			HexVector.new(floor(plane_hex.q), floor(plane_hex.r), ceil(plane_hex.s)),
			HexVector.new(ceil(plane_hex.q), floor(plane_hex.r), floor(plane_hex.s)),
			HexVector.new(floor(plane_hex.q), ceil(plane_hex.r), floor(plane_hex.s)),
			HexVector.new(floor(plane_hex.q), floor(plane_hex.r), floor(plane_hex.s))
		]
		
		#calculate closest rounded vector
		var minDist = INF
		for r in roundedVectors:
			var dist = HexMath.axis_to_2D(r).distance_to(plane_pos)
			if dist < minDist:
				minDist = dist
				plane_hex = r
			
		plane_hex.q = int(plane_hex.q)
		plane_hex.r = int(plane_hex.r)
		plane_hex.s = int(plane_hex.s)
		return HexMath.axis_to_2D(plane_hex)
	return null
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	singleton = self
	
	EditorIcon.icons = []
	
	placementData = PlacementData.new()
	
	for i in range(len(data.data_list)):
		var icon: TileIcon = TileIconPrefab.instantiate()
		icon.initialize(i)
		tileGrid.add_child(icon)
	
	for i in range(len(entityData.entityList)):
		var icon: EntityIcon = EntityIconPrefab.instantiate()
		icon.initialize(i)
		entityGrid.add_child(icon)
	
	create_hex_at_pos(Vector2(0, 0), 0, 0)
	
	lastMousePos = get_viewport().get_mouse_position()
	
	

func create_hex_at_pos(pos: Vector2, height: int, data_id: int):
	var hextile: HexTile = data.get_data(data_id)
	#set paramters (get_data method clones the resource)
	hextile.hex_pos = HexVector.fromCubePos(pos)
	hextile.height = height
	place_hex(hextile)

func generate_from_map() -> void:
	for hex in hexmap.map.values():
		register_hex(hex)

func place_hex(to_place: HexTile) -> void:
	var cubePos = HexVector.toCubePos(to_place.hex_pos)
	hexmap.map[cubePos] = to_place
	register_hex(to_place)

##place_hex without adding it to hex map
func register_hex(to_place: HexTile): 
	var cubePos = HexVector.toCubePos(to_place.hex_pos)
	to_place.id = MAX_HEX_ID
	MAX_HEX_ID += 1
	id_lookup[cubePos] = to_place.id

	spawn_hex(to_place, to_place.id)

func remove_hex(to_remove: HexTile) -> void:
	var cubePos = HexVector.toCubePos(to_remove.hex_pos)
	hexmap.map.erase(cubePos)
	id_lookup.erase(cubePos)
	
	despawn_hex(to_remove.id)

func spawn_hex(hextile: HexTile, id: int, add_to_lookup = true) -> Hex:
	var cPos = HexVector.toCubePos(hextile.hex_pos)
	var coordinate = [cPos.x, cPos.y]
	
	var newTile: Hex = HexTilePrefab.instantiate()
	
	if add_to_lookup:
		hextile_lookup[id] = newTile
	
	newTile.initialize(hextile)
	newTile.forceTint(1)
	add_child(newTile)
	
	return newTile

func despawn_hex(id: int) -> void:
	var hex: Hex = hextile_lookup[id]
	hextile_lookup.erase(id)
	
	var cubePos = HexVector.toCubePos(hex.data.hex_pos)
	id_lookup.erase(cubePos)
	
	for entity in hex.storedEntities:
		entity.queue_free()
	
	hex.queue_free()
	
	
func valid_placement(hexpos: HexVector):
	print(hexpos.q, ",",round(hexpos.q))
	for pos in id_lookup:
		if HexVector.toCubePos(hexpos).distance_to(pos) < 0.1:
			return false
	return true


func set_selection_mode(mode: PlacementData.SelectionMode):
	placementData.selectionMode = mode

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("cancel_action"):
		set_selection_mode(PlacementData.SelectionMode.NONE)
	#change height
	if inMenu and placementData.selectionMode == PlacementData.SelectionMode.HEX:
		#set visibility
		placementData.ghost.ghost_hex.visible = true
		
		if Input.is_action_just_pressed("mouseWheelUp") and Input.is_action_pressed("aux"):
			placementData.current_placement_height += 1
		elif Input.is_action_just_pressed("mouseWheelDown") and Input.is_action_pressed("aux"):
			placementData.current_placement_height -= 1
			placementData.update_ghost_position(delta)
		
		var mouse_pos = get_viewport().get_mouse_position()

		if mouse_pos != lastMousePos:
			lastMousePos = mouse_pos
			var ray_origin = cam.project_ray_origin(mouse_pos)
			var ray_dir = cam.project_ray_normal(mouse_pos)
			#calculate plane intersection
			var hex_plane = Plane(Vector3.UP, placementData.current_placement_height*Hex.TILE_HEIGHT)
			hex_inst = hex_plane.intersects_ray(ray_origin, ray_dir)
		
		if hex_inst != null:
			var plane_pos = Vector2(hex_inst.x, hex_inst.z)
			var plane_hex: HexVector = HexMath._2D_to_axis(plane_pos)
			
			var roundedVectors = [
				HexVector.new(ceil(plane_hex.q), ceil(plane_hex.r), ceil(plane_hex.s)),
				HexVector.new(floor(plane_hex.q), ceil(plane_hex.r), ceil(plane_hex.s)),
				HexVector.new(ceil(plane_hex.q), floor(plane_hex.r), ceil(plane_hex.s)),
				HexVector.new(ceil(plane_hex.q), ceil(plane_hex.r), floor(plane_hex.s)),
				HexVector.new(floor(plane_hex.q), floor(plane_hex.r), ceil(plane_hex.s)),
				HexVector.new(ceil(plane_hex.q), floor(plane_hex.r), floor(plane_hex.s)),
				HexVector.new(floor(plane_hex.q), ceil(plane_hex.r), floor(plane_hex.s)),
				HexVector.new(floor(plane_hex.q), floor(plane_hex.r), floor(plane_hex.s))
			]
			
			#calculate closest rounded vector
			var minDist = INF
			for r in roundedVectors:
				var dist = HexMath.axis_to_2D(r).distance_to(plane_pos)
				if dist < minDist:
					minDist = dist
					plane_hex = r
				
			plane_hex.q = int(plane_hex.q)
			plane_hex.r = int(plane_hex.r)
			plane_hex.s = int(plane_hex.s)
			
			if valid_placement(plane_hex):
				placementData.update_parameters(delta, plane_hex)
			else:
				placementData.update_ghost_position(delta)
		else:
			placementData.update_ghost_position(delta)
	else:
		#set visibility
		placementData.ghost.ghost_hex.visible = false
			
	
func select_hex_type(id: int):
	placementData.selectionMode = PlacementData.SelectionMode.HEX
	placementData.set_type(id)

func select_entity_type(id: int):
	placementData.selectionMode = PlacementData.SelectionMode.ENTITY
	placementData.set_entity_type(id)
	
func place_entity(tile: HexTile, id: int = placementData.current_entity_id):
	var entity_command: Array[int] = [BattleController.Command.SUMMON_ENTITY, id, tile.hex_pos.q, tile.hex_pos.r, tile.hex_pos.s, tile.height, -1, -1]
	var entity = BattleController.createEntity(entity_command, entityData, -1, hexmap, null)
	entity.always_visible = true
	add_child(entity)

func remove_entity(tile: HexTile, entity: FieldEntity):
	remove_child(entity)
	tile.hex.storedEntities.erase(entity)
	entity.queue_free()
	
			
func _input(event) -> void:
	if event is InputEventMouseButton:
		if inMenu and placementData.selectionMode == PlacementData.SelectionMode.HEX and event.pressed == true:
			if event.button_index == 1 and valid_placement(placementData.current_hex.hex_pos):
				place_hex(placementData.current_hex.clone())
	pass # Replace with function body.

func clear() -> void:
	for hex in hextile_lookup.values():
		remove_hex(hex.data)
	hextile_lookup = {}
	id_lookup = {}
	MAX_HEX_ID = 0

func _on_tilemenu_mouse_entered() -> void:
	inMenu = true


func _on_tilemenu_mouse_exited() -> void:
	inMenu = false


func _on_load() -> void:
	clear()
	hexmap.construct_using_string_form(outputText.text, data)
	generate_from_map()
	hexmap.construct_entities_using_string_form(outputText.text,data,null)
	
		


func _on_save() -> void:
	outputText.text = hexmap.string_form()
