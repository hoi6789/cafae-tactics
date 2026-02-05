class_name Floodfill

var graph: BFSGraph
var s = 0
var t = -1
var max_dist = 0
var found: Array[int] = []
var depths: Dictionary[int, float] = {}
var searched: Dictionary[int, bool] = {}
var queue = Queue.new()

func _init(_graph: BFSGraph, start_index: int, _max_dist: int):
	graph = _graph
	s = start_index
	max_dist = _max_dist
	depths[s] = 0
# Called when the node enters the scene tree for the first time.
		

func evaluate():
	if len(found) != 0:
		return
	queue.push(s)
	while queue.size > 0:
		var index = queue.pop()
		var node = graph.get_node(index)
		for edge: BFSEdge in node.outward_edges:
			var u = edge.to
			if u in searched:
				continue
			searched[u] = true
			var depth = depths[index]+edge.weight
			if depth < max_dist:
				depths[u] = depth
				queue.push(u)
				
			if depth <= max_dist:
				found.push_back(u)
		
	
