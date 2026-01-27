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
		map[pos] = HexTile.new(current_id, HexVector.fromCubePos(pos), HexTile.TerrainType.BASIC)
		current_id += 1

func get_hex(hex_vec: HexVector) -> HexTile:
	var cPos = HexVector.toCubePos(hex_vec)
	return map[cPos]

func getIntermovementCost(a: HexTile, b: HexTile):
	return (a.getMovementCost() + b.getMovementCost())/2

func rebuild_graph():
	graph = BFSGraph.new()
	solutions = {}
	#nodes
	for hex: HexTile in map.keys():
		graph.insert_node(0,hex.id)
		hex_list[hex.id] = hex
	#edges
	for hex: HexTile in map.keys():
		for dir in HexVector.DIRECTIONS:
			var adj: HexTile = get_hex(HexVector.add(hex.hex_pos, dir))
			if adj != null:
				var cost = getIntermovementCost(hex, adj)
				graph.insert_edge(hex.id,adj.id,cost)

func _calcShortestPath(from: HexTile, to: HexTile):
	var solver: Djikstra = Djikstra.new(graph, from.id)
	solver.calc_distance()
	solutions[from.id] = solver

func getShortestPath(from: HexTile, to: HexTile) -> Array[HexTile]:
	if solutions[from.id] == null:
		_calcShortestPath(from, to)
	
	var id_path: Array = solutions[from.id].path[to.id]
	var path = []
	
	for id in id_path:
		path.push_back(hex_list[id])
	
	return path
