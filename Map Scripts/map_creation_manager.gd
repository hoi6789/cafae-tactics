extends Node

@export var HexTilePrefab: PackedScene
@export var data: HexData
@export var cam: Camera3D

var current_placement_height: int = 0
var ghost_hex: Hex
var current_hex: HexTile
var hexmap: HexagonMap = HexagonMap.new()

var hextile_lookup: Dictionary[int, Hex]
var id_lookup: Dictionary[Vector2, int]

var MAX_HEX_ID = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ghost_hex = spawn_hex(data.get_data(0), -1)
	current_hex = data.get_data(0)
	
	create_hex_at_pos(Vector2(0, 0), 1, 0)
	create_hex_at_pos(Vector2(2, 1), 0, 1)
	
	

func create_hex_at_pos(pos: Vector2, height: int, data_id: int):
	var hextile: HexTile = data.get_data(data_id)
	#set paramters (get_data method clones the resource)
	hextile.hex_pos = HexVector.fromCubePos(pos)
	hextile.height = height
	place_hex(hextile)

func place_hex(to_place: HexTile) -> void:
	var cubePos = HexVector.toCubePos(to_place.hex_pos)
	to_place.id = MAX_HEX_ID
	MAX_HEX_ID += 1
	
	hexmap.map[cubePos] = to_place
	id_lookup[cubePos] = to_place.id

	spawn_hex(to_place, to_place.id)

func remove_hex(to_remove: HexTile) -> void:
	var cubePos = HexVector.toCubePos(to_remove.hex_pos)
	hexmap.map.erase(cubePos)
	
	despawn_hex(to_remove.id)

func spawn_hex(hextile: HexTile, id: int) -> Hex:
	var cPos = HexVector.toCubePos(hextile.hex_pos)
	var coordinate = [cPos.x, cPos.y]
	
	var newTile: Hex = HexTilePrefab.instantiate()
	
	hextile_lookup[id] = newTile
	
	newTile.initialize(hextile)
	newTile.forceTint(1)
	add_child(newTile)
	
	return newTile

func despawn_hex(id: int) -> void:
	var hex: Hex = hextile_lookup[id]
	hextile_lookup.erase(id)
	
	var cubePos = HexVector.toCubePos(hex.hex_pos)
	id_lookup.erase(cubePos)
	hex.queue_free()
	
	
func valid_placement(hexpos: HexVector):
	return HexVector.toCubePos(hexpos) not in id_lookup

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#change height
	if Input.is_action_just_pressed("mouseWheelUp") and Input.is_action_pressed("aux"):
		current_placement_height += 1
	elif Input.is_action_just_pressed("mouseWheelDown") and Input.is_action_pressed("aux"):
		current_placement_height -= 1
	
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = cam.project_ray_origin(mouse_pos)
	var ray_dir = cam.project_ray_normal(mouse_pos)
	#calculate plane intersection
	var hex_plane = Plane(Vector3.UP, current_placement_height*Hex.TILE_HEIGHT)
	var hex_inst = hex_plane.intersects_ray(ray_origin, ray_dir)
	
	if hex_inst != null:
		var plane_pos = Vector2(hex_inst.x, hex_inst.z)
		var plane_hex: HexVector = HexMath._2D_to_axis(plane_pos)
		
		plane_hex.q = round(plane_hex.q)
		plane_hex.r = round(plane_hex.r)
		plane_hex.s = round(plane_hex.s)
		
		if valid_placement(plane_hex):
			current_hex.height = current_placement_height
			current_hex.hex_pos = plane_hex
			#set ghost
			ghost_hex.data.height = current_placement_height
			ghost_hex.setPosition(HexVector.toCubePos(plane_hex))
	

	
			
func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true and valid_placement(current_hex.hex_pos):
			place_hex(current_hex.clone())
	pass # Replace with function body.
