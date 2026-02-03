class_name Djikstra

var graph: BFSGraph
var s = 0
var t = -1
var dist: Array[float] = []
var path: Array[Array] = []
var queue = Heap.new([],false,compare_distance)
var destination: BFSNode = null

func g(n: BFSNode):
	return n.key
	
func h(n: BFSNode):
	return (destination.pos - n.pos).length()
	
func f(n: BFSNode):
	if destination == null:
		return g(n)
	else:
		return g(n) + h(n)


func compare_distance(a, b) -> bool:
	return f(graph.get_node(a.index)) < f(graph.get_node(b.index))

func _init(_graph: BFSGraph, start_index: int, end_index: int = -1):
	graph = _graph
	s = start_index
	t = end_index
	
	if t != -1:
		destination = graph.get_node(t)
	
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

		if u.key > dist[u.index]:
			continue
		
		for adj in u.outward_edges:
			var v_index = adj.to

			if dist[v_index] > dist[u.index] + adj.weight:
				dist[v_index] = dist[u.index] + adj.weight
				path[v_index] = path[u.index] + [adj]
				graph.get_node(v_index).key = dist[v_index]
				queue.insert(graph.get_node(v_index))
		
		if u == destination:
			break
				
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass
