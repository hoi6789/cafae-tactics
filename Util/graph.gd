class_name BFSGraph

var size = 0
var nodes: Dictionary[int, BFSNode] = {}
var edges: Array[BFSEdge] = []
var edge_map: Dictionary[Array, BFSEdge] = {}

# Called when the node enters the scene tree for the first time.
func _init():
	pass

func get_node(index) -> BFSNode:
	return nodes[index]

func insert(key, edges: Array[BFSEdge], _index=-1): ##edges are indices of all connected nodes
	var n: BFSNode = BFSNode.new(key, edges, size)
	size += 1
	for edge in edges:
		edge_map[[edge.from, edge.to]] = edge
	if _index == -1:
		n.index = size-1
	else:
		n.index = _index
	nodes[n.index] = n
	
func insert_node(key, index=-1): ##edges are indices of all connected nodes
	if index == -1:
		index = size
	var n: BFSNode = BFSNode.new(key, [], index)
	size += 1
	nodes[n.index] = n

func insert_edge(from: int, to: int, weight: float): ##edges are indices of all connected nodes
	var e: BFSEdge = BFSEdge.new(weight, from, to)
	edges.push_back(e)
	nodes[from].outward_edges.push_back(e)
	nodes[to].inward_edges.push_back(e)

func get_edge(from: BFSEdge , to: BFSEdge) -> BFSEdge:
	return edge_map[[from, to]]

func connected_nodes(index: int) -> Array[BFSNode]:
	var A: Array[BFSNode] = []
	for edge in nodes[index].edges:
		A.push_back(nodes[edge.to])
	return A
