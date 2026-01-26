class_name BFSNode

var key = null
var edges: Array[BFSEdge] = []
var outward_edges: Array[BFSEdge] = []
var inward_edges: Array[BFSEdge] = []
var index = 0
var explored = false

func _init(_key, _e: Array[BFSEdge], _ind=0):
	key = _key
	edges = _e
	index = _ind
	
	for e in edges:
		if e.to == index:
			inward_edges.push_back(e)
		else:
			outward_edges.push_back(e)
