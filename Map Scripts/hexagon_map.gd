class_name HexagonMap

const HEIGHT_STEP_MAX = 1 ##maximum height that a unit can naturally step up

var map: Dictionary[Vector2, HexTile] = {}
var hex_list: Dictionary[int, HexTile] = {}
var graph: BFSGraph
var pathfinder: Djikstra
var solutions: Dictionary[Vector2i, Djikstra] = {}
var djikstra_solutions: Dictionary[Vector2, Djikstra] = {}
var floodfills: Dictionary[Vector2i, Floodfill] = {}

func _init():
	map = {}

func reset():
	map = {}
	hex_list = {}
	solutions = {}
	djikstra_solutions = {}
	floodfills = {}

func force_generate(cubePositions: Array):
	var current_id = 0
	for pos: Vector2 in cubePositions:
		var hex =  HexTile.new(current_id, HexVector.fromCubePos(pos), 0, HexTile.TerrainType.BASIC)
		map[pos] = hex
		hex_list[current_id] = hex
		current_id += 1
	rebuild_graph()

func force_generate_with_terrain_types(cubePositions: Array):
	var current_id = 0
	for pos3: Array in cubePositions:
		var pos = Vector2(pos3[0], pos3[1])
		
		var h = 5*pos3[2]
		if h <= 0:
			h *= 5
		var dI = (round(pos3[3]))
		var hex =  HexTile.new(current_id, HexVector.fromCubePos(pos), round(h), HexTile.TerrainType.values()[dI])
		hex.data_index = dI
		map[pos] = hex
		hex_list[current_id] = hex
		current_id += 1
	print(string_form())
	rebuild_graph()
	
func snap_hex(hex_vec: HexVector) -> HexVector:
	return HexVector.new(round(hex_vec.q),round(hex_vec.r))

func get_hex(hex_vec: HexVector) -> HexTile:
	var cPos = HexVector.toCubePos(snap_hex(hex_vec))
	if cPos in map:
		return map[cPos]
	return null

func _shape_thread(shape: Array[Vector2], output: Array, hex: HexTile):
	if PolyMath.PointInPoly(HexMath.axis_to_2D(hex.hex_pos),shape):
			output.push_back(hex)

func get_hex_in_shape(shape: Array[HexVector], sight_point: HexTile, origin: HexVector = null) -> Array[HexTile]:
	var inside: Array[HexTile] = []
	var cart_shape: Array[Vector2]
	var max_dist: float = 0
	if origin == null:
		origin = snap_hex(HexMath.average(shape))
		
	for vert in shape:
		max_dist = max(max_dist, HexVector.dist(origin, vert))
		var v = HexMath.axis_to_2D(vert)
		##print("old length: ", (v - cart_origin).length())
		#v += (v - cart_origin).normalized()*0.5
		##print("new length: ", (v - cart_origin).length())
		cart_shape.push_back(v)
	#InputManager.instance.last_shape = cart_shape
	#InputManager.instance.drawY = sight_point.height*HexMath.HEX_HEIGHT
	var t1 = Time.get_ticks_msec()
	var hexes: Array[HexTile] = getHexesInRange(origin, ceil(max_dist))
	var origin_hex: HexTile = get_hex(origin)
	if origin_hex != null:
		hexes += [origin_hex]
	print("hexes: ", Time.get_ticks_msec()-t1)
	var threads: Array[Thread] = []
	t1 = Time.get_ticks_msec()
	var MAX_THREADS = 16
	for hex in hexes:
		if hex == null or blocksLOS(hex, sight_point) or blocksLOSExclusive(hex, sight_point) or !inLOSAngle(hex, sight_point):
			continue
		for i in len(threads):
			if len(threads) < MAX_THREADS:
				break
			if len(threads) > 0:
				threads[0].wait_to_finish()
				threads.remove_at(0)
		var copy_arr: Array[Vector2] = []
		copy_arr.assign(cart_shape)
		
		var thread: Thread = Thread.new()
		thread.start(_shape_thread.bind(copy_arr,inside,hex))
		threads.push_back(thread)
	for t in threads:
		t.wait_to_finish()
	print("shape filling: ", Time.get_ticks_msec()-t1)
	return inside

static func getIntermovementCost(a: HexTile, b: HexTile):
	var hCost = HexTile.JUMP_COST_MOD*HexTile.JUMP_COST*HexTile.getHeightDifference(a, b) + HexTile.JUMP_COST_BIAS*sign(HexTile.getHeightDifference(a, b))
	return hCost+(a.getMovementCost() + b.getMovementCost())/2

func rebuild_graph():
	graph = BFSGraph.new()
	solutions = {}
	#nodes
	for hex: HexTile in map.values():
		graph.insert_node(0,hex.id)
		
	#edges
	for hex: HexTile in map.values():
		for dir in HexVector.DIRECTIONS:
			var nextpos = HexVector.add(hex.hex_pos, dir)
			var adj: HexTile = get_hex(nextpos)
			
			if adj != null and adj.height-hex.height <= HEIGHT_STEP_MAX:
				var cost = getIntermovementCost(hex, adj)
				graph.insert_edge(hex.id,adj.id,cost)

func _calcShortestPath(from: HexTile, to: HexTile):
	#no a*: var solver: Djikstra = Djikstra.new(graph, from.id)
	var solver_thread: Thread = Thread.new()
	var solver_astar: Djikstra = Djikstra.new(graph, from.id, to.id)
	
	solver_thread.start(solver_astar.calc_distance.bind())
	while solver_thread.is_alive():
		await InputManager.instance.get_tree().process_frame
	solver_thread.wait_to_finish()
	solutions[Vector2i(from.id, to.id)] = solver_astar

func _calcShortestRange(from: HexTile, limit: float): ##Shortest path with djikstra and a path limit
	#no a*: var solver: Djikstra = Djikstra.new(graph, from.id)
	var solver_thread: Thread = Thread.new()
	var solver_dj: Djikstra = Djikstra.new(graph, from.id, -1)
	solver_dj.set_limit(limit)
	
	solver_thread.start(solver_dj.calc_distance.bind())
	while solver_thread.is_alive():
		await InputManager.instance.get_tree().process_frame
	solver_thread.wait_to_finish()
	djikstra_solutions[Vector2(from.id, limit)] = solver_dj

func _runFloodfill(source: HexTile, dist: int):
	#no a*: var solver: Djikstra = Djikstra.new(graph, from.id)
	var solver_thread: Thread = Thread.new()
	var solver: Floodfill = Floodfill.new(graph, source.id, dist)
	
	solver_thread.start(solver.evaluate.bind())
	while solver_thread.is_alive():
		await InputManager.instance.get_tree().process_frame
	solver_thread.wait_to_finish()
	floodfills[Vector2i(source.id, dist)] = solver


func getHexesInRange(origin: HexVector, dist: int) -> Array[HexTile]:
	var arr: Array[HexTile] = []

	for q in range(-dist, dist+1):
		for r in range(-dist, dist+1):
			if q == 0 and r == 0:
				continue
			var s = -(q+r)
			if abs(s)>dist:
				continue
			var hex_pos = HexVector.add(origin, HexVector.new(q,r,s))
			##print(hex_pos.q,",",hex_pos.r)
			var hex = get_hex(hex_pos)
			if hex != null:
				arr.push_back(hex)
	return arr

func getSight(origin: HexVector, dist: int) -> Array[HexTile]:
	var poly: Array[HexTile] = getHexesInRange(origin, dist) 
	poly.push_back(get_hex(origin))
	var seen: Array[HexTile] = []
	
	var originv2: Vector2 = HexMath.axis_to_2D(origin)
	var origintile: HexTile = get_hex(origin)
	
	for hex in poly:
		if blocksLOS(hex, origintile):
			continue
		var dir = HexMath.axis_to_2D(hex.hex_pos) - originv2
		var angle = atan2(dir.y, dir.x)
		
		var rtile = raycast(origin, angle, float(dist), 0.1, hex)

		if rtile.id != hex.id:
			continue
		seen.push_back(hex)
	return seen

func getSight_old(origin: HexVector, dist: int) -> Array:
	var steps = 100
	var poly: Array[HexVector] = []
	for i in range(steps):
		poly.push_back(raycast(origin,i*2*PI/steps,float(dist),1.0).hex_pos)
	var t: Thread = Thread.new()
	t.start(get_hex_in_shape.bind(poly, get_hex(origin),snap_hex(origin)))
	while t.is_alive():
		await InputManager.instance.get_tree().process_frame
	return t.wait_to_finish()
	#return [arr, sightPower]

func inLOSAngle(tile: HexTile, origin: HexTile):
	var dy = (tile.height-origin.height)*HexMath.HEX_HEIGHT
	var dr = HexVector.dist(origin.hex_pos, tile.hex_pos)
	return abs(atan2(dy, dr)) < deg_to_rad(30)

func blocksLOS(tile: HexTile, origin: HexTile):
	var dy_unscaled = (tile.height-origin.height)
	
	return dy_unscaled > 2
	
func blocksLOSExclusive(tile: HexTile, origin: HexTile):
	print("en count:",len(tile.hex.storedEntities))
	for obj in tile.hex.storedEntities:
		var o = (obj as FieldEntity)
		if !o.canSeeThrough() and o.hex_height >= origin.height:
			return true
	
	return false

func raycast(origin: HexVector, angle: float, distance: float, resolution: float = 0.1, finalHex: HexTile = null) -> HexTile:
	var t = 0
	var cart_dir = Vector2(cos(angle),sin(angle))*HexMath.GLOBAL_OFFSET
	
	var cart_origin_3d = HexMath.axis_to_3D(origin.q, origin.r)
	var cart_origin = Vector2(cart_origin_3d.x, cart_origin_3d.z)
	var origin_hex = get_hex(origin)
	var current_hex: HexTile = origin_hex
	var last_found_hex = origin_hex
	
	var current_pos: HexVector = origin
	
	#initial check
	if finalHex != null and current_hex == finalHex:
		return last_found_hex
	
	while t < distance:
		var pos: Vector2 = cart_origin + cart_dir*t
		var hex_pos: HexVector = HexMath._2D_to_axis(pos)
		var grid_hex: HexVector = snap_hex(hex_pos)
		
		if !HexVector._equals(grid_hex, current_pos):
			current_pos = grid_hex
			current_hex = get_hex(grid_hex)
			
			if current_hex != null:
				var double_last_found_hex = last_found_hex
				last_found_hex = current_hex
				if finalHex != null and current_hex == finalHex:
					break
			if current_hex != null and (blocksLOS(current_hex, origin_hex) or blocksLOSExclusive(current_hex, origin_hex)):
				break
		t += resolution
	return last_found_hex
	
func getHexesWithShortestPathDistance(origin: HexVector, dist: int, check_limit: int = -1) -> Array[HexTile]:
	if check_limit == -1:
		check_limit = dist
	var arr: Array[HexTile] = []
	var origin_hex = get_hex(origin)
	for q in range(-check_limit, check_limit+1):
		for r in range(-check_limit, check_limit+1):
			if q == 0 and r == 0:
				continue
			var s = -(q+r)
			if abs(s)>check_limit:
				continue
			var hex_pos = HexVector.add(origin, HexVector.new(q,r,s))
			var hex = get_hex(hex_pos)
			if hex != null and await getShortestDistance(origin_hex, hex, check_limit) <= dist:
				arr.push_back(hex)
	return arr

func getShortestPath(from: HexTile, to: HexTile) -> Array[HexTile]:
	if !solutions.has(Vector2i(from.id, to.id)):
		await _calcShortestPath(from, to)
	
	var id_path: Array = solutions[Vector2i(from.id, to.id)].path[to.id]
	
	if len(id_path) == 0:
		return []
	
	var path: Array[HexTile] = []
	
	path.push_back(hex_list[id_path[0].from])
	for id in id_path:
		path.push_back(hex_list[id.to])
	return path
	
func getShortestDistance(from: HexTile, to: HexTile, limit: float) -> float:
	if !djikstra_solutions.has(Vector2(from.id, limit)):
		await _calcShortestRange(from, limit)
	
	return djikstra_solutions[Vector2(from.id, limit)].dist[to.id]

func getFloodedRange(from: HexTile, flood_range: int) -> Array[HexTile]:
	if !floodfills.has(Vector2i(from.id, flood_range)):
		await _runFloodfill(from, flood_range)
	
	var id_arr: Array = floodfills[Vector2i(from.id, flood_range)].found
	
	if len(id_arr) == 0:
		return []
	
	var arr: Array[HexTile] = []
	
	for id in id_arr:
		arr.push_back(hex_list[id])
	return arr

#data management
func hex_string(h: HexTile) -> String:
	var s: String = ""
	s += str(int(h.data_index)) + "," + str(int(h.height))
	return s

func hex_from_string(s: String, data: HexData) -> HexTile:
	var hex_data = s.split(",")
	
	var ind = int(hex_data[0])
	var height = int(hex_data[1])
	
	var hex: HexTile = data.get_data(ind)
	hex.height = height
	return hex

func string_form() -> String:
	var bounds_minX = INF
	var bounds_maxX = -INF
	var bounds_minY = INF
	var bounds_maxY = -INF
	
	for pos in map:
		if pos.x < bounds_minX:
			bounds_minX = pos.x
		if pos.x > bounds_maxX:
			bounds_maxX = pos.x
		if pos.y < bounds_minY:
			bounds_minY = pos.y
		if pos.y > bounds_maxY:
			bounds_maxY = pos.y
	var header = str(bounds_minX)+","+str(bounds_maxX)+" "+str(bounds_minY)+","+str(bounds_maxY)
	var form = header+"\n"
	for x in range(bounds_minX, bounds_maxX+1):
		for y in range(bounds_minY, bounds_maxY+1):
			var subpos = Vector2(x, y)
			if subpos in map:
				form += hex_string(map[subpos])+"|"
			else:
				form += "x|"
			
	return form

func construct_using_string_form(form: String, hex_atlas: HexData) -> void:
	reset()
	var lines = form.split("\n")
	
	var header = lines[0]
	var map_data = lines[1].split("|")
	
	var bounds = header.split(" ")
	var xBounds = bounds[0].split(",")
	var yBounds = bounds[1].split(",")
	
	var bounds_minX = int(xBounds[0])
	var bounds_maxX = int(xBounds[1])
	var bounds_minY = int(yBounds[0])
	var bounds_maxY = int(yBounds[1])
	
	var data_index = 0
	var current_id = 0
	
	for x in range(bounds_minX, bounds_maxX+1):
		for y in range(bounds_minY, bounds_maxY+1):
			var dat = map_data[data_index]
			data_index += 1
			
			if dat == "x" or dat == "":
				continue
			
			var hex_dat = dat.split(";")
			
			var hex_str = hex_dat[0]
			var subpos = Vector2(x, y)
			
			
			var hex: HexTile = hex_from_string(hex_str, hex_atlas)
			hex.hex_pos = HexVector.fromCubePos(subpos)
			hex.id = current_id
			
			map[subpos] = hex
			hex_list[current_id] = hex
			
			current_id += 1
	
	rebuild_graph()

func construct_entities_using_string_form(form: String, hex_atlas: HexData, controller: BattleController, inputManager: InputManager = null, root: Node3D = null, entityData: FieldEntityAtlas = null) -> void:
	var lines = form.split("\n")
	
	var header = lines[0]
	var map_data = lines[1].split("|")
	
	var bounds = header.split(" ")
	var xBounds = bounds[0].split(",")
	var yBounds = bounds[1].split(",")
	
	var bounds_minX = int(xBounds[0])
	var bounds_maxX = int(xBounds[1])
	var bounds_minY = int(yBounds[0])
	var bounds_maxY = int(yBounds[1])
	
	var data_index = 0
	var current_id = 0
	
	for x in range(bounds_minX, bounds_maxX+1):
		for y in range(bounds_minY, bounds_maxY+1):
			var dat = map_data[data_index]
			data_index += 1
			
			if dat == "x" or dat == "":
				continue
			
			var hex_dat = dat.split(";")
			
			var hex_str = hex_dat[0]
			var subpos = Vector2(x, y)
			
			
			var hex: HexTile = hex_from_string(hex_str, hex_atlas)
			var hpos: HexVector = HexVector.fromCubePos(subpos)
			hex.id = current_id
			
			if len(hex_dat) > 1:
				var str_entity = hex_dat[1] 
				##summons an entity at a target hex. params: entity type id, q of hex, r of hex, h of hex tile, controller of unit, team of unit
				var entity_command: Array[int] = [BattleController.Command.SUMMON_ENTITY, int(str_entity), hpos.q, hpos.r, hpos.s, hex.height, -1, -1]
				if controller != null:
					controller.processInput(entity_command)
				else:
					var entity = BattleController.createEntity(entity_command, entityData, 0, self, inputManager)
					root.add_child(entity)
			
			current_id += 1

#map instantiation
func spawn_hex(hextile: HexTile, prefab: PackedScene, parent: Node) -> Hex:
	var cPos = HexVector.toCubePos(hextile.hex_pos)
	
	var newTile: Hex = prefab.instantiate()
	
	newTile.initialize(hextile)

	parent.add_child(newTile)
	
	return newTile
