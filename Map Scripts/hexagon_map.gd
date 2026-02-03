class_name HexagonMap

var map: Dictionary[Vector2, HexTile] = {}
var hex_list: Dictionary[int, HexTile] = {}
var graph: BFSGraph
var pathfinder: Djikstra
var solutions: Dictionary[int, Djikstra] = {}

func _init():
	map = {}

func force_generate(cubePositions: Array):
	var current_id = 0
	for pos: Vector2 in cubePositions:
		var hex =  HexTile.new(current_id, HexVector.fromCubePos(pos), HexTile.TerrainType.BASIC)
		map[pos] = hex
		hex_list[current_id] = hex
		current_id += 1
	rebuild_graph()

func get_hex(hex_vec: HexVector) -> HexTile:
	var cPos = HexVector.toCubePos(hex_vec)
	if cPos in map:
		return map[cPos]
	return null

func getIntermovementCost(a: HexTile, b: HexTile):
	return (a.getMovementCost() + b.getMovementCost())/2

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
			if adj != null:
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
	solutions[from.id] = solver_astar
	

func getShortestPath(from: HexTile, to: HexTile) -> Array[HexTile]:
	if !solutions.has(from.id):
		await _calcShortestPath(from, to)
	
	var id_path: Array = solutions[from.id].path[to.id]
	
	if len(id_path) == 0:
		return []
	
	var path: Array[HexTile] = []
	
	path.push_back(hex_list[id_path[0].from])
	for id in id_path:
		path.push_back(hex_list[id.to])
	
	
	return path
