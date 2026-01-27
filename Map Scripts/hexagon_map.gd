class_name HexagonMap

var map: Dictionary[Vector2, Hex] = {}
var hex_list: Dictionary[int, Hex] = {}
var graph: BFSGraph
var pathfinder: Djikstra
var solutions: Dictionary[int, Djikstra] = {}

func _init():
	map = {}

func get_hex(hex_vec: HexVector) -> Hex:
	var cPos = HexVector.toCubePos(hex_vec)
	return map[cPos]

func getIntermovementCost(a: Hex, b: Hex):
	return (a.getMovementCost() + b.getMovementCost())/2

func rebuild_graph():
	graph = BFSGraph.new()
	solutions = {}
	#nodes
	for hex: Hex in map.keys():
		graph.insert_node(0,hex.id)
		hex_list[hex.id] = hex
	#edges
	for hex: Hex in map.keys():
		for dir in HexVector.DIRECTIONS:
			var adj: Hex = get_hex(HexVector.add(hex.hex_pos, dir))
			if adj != null:
				var cost = getIntermovementCost(hex, adj)
				graph.insert_edge(hex.id,adj.id,cost)

func _calcShortestPath(from: Hex, to: Hex):
	var solver: Djikstra = Djikstra.new(graph, from.id)
	solver.calc_distance()
	solutions[from.id] = solver

func getShortestPath(from: Hex, to: Hex) -> Array[Hex]:
	if solutions[from.id] == null:
		_calcShortestPath(from, to)
	
	var id_path: Array = solutions[from.id].path[to.id]
	var path = []
	
	for id in id_path:
		path.push_back(hex_list[id])
	
	return path
