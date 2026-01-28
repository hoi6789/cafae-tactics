class_name Djikstra

var graph: BFSGraph
var s = 0
var dist: Array[float] = []
var path: Array[Array] = []
var queue = Heap.new([],false,compare_distance)

func compare_distance(a, b) -> bool:
	return graph.get_node(a.index).key < graph.get_node(b.index).key

func _init(_graph: BFSGraph, start_index: int):
	graph = _graph
	s = start_index
	for i in range(graph.size):
		dist.push_back(INF)
		path.push_back([])
	dist[s] = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func calc_distance():
	for node in graph.nodes.values():
		node.key = 0
	
	queue.insert(graph.get_node(s))

	while queue.size > 0:
		var u: BFSNode = queue.extract()
		
		print(u.key, ", ", dist[u.index])
		if u.key > dist[u.index]:
			continue
		
		for adj in u.outward_edges:
			var v_index = adj.to
			print(v_index, ": ", dist[v_index], ", ", dist[u.index] + adj.weight)
			if dist[v_index] > dist[u.index] + adj.weight:
				dist[v_index] = dist[u.index] + adj.weight
				path[v_index] = path[u.index] + [adj]
				graph.get_node(v_index).key = dist[v_index]
				queue.insert(graph.get_node(v_index))
				
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass
