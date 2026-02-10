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
		var hex =  HexTile.new(current_id, HexVector.fromCubePos(pos), round(h), HexTile.TerrainType.values()[(round(pos3[3]))])
		map[pos] = hex
		hex_list[current_id] = hex
		current_id += 1
	rebuild_graph()

func get_hex(hex_vec: HexVector) -> HexTile:
	var cPos = HexVector.toCubePos(hex_vec)
	if cPos in map:
		return map[cPos]
	return null

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
			
			if adj != null and HexTile.getHeightDifference(hex, adj) <= HEIGHT_STEP_MAX:
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
			var hex = get_hex(hex_pos)
			if hex != null:
				arr.push_back(hex)
	return arr
	
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
