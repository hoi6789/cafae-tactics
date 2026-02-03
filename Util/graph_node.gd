class_name BFSNode

var key = null
var pos: Vector3
var edges: Array[BFSEdge] = []
var outward_edges: Array[BFSEdge] = []
var inward_edges: Array[BFSEdge] = []
var index = 0
var explored = false

func _init(_key, _e: Array[BFSEdge], _ind=0, _pos: Vector3 = Vector3(0,0,0)):
	key = _key
	edges = _e
	index = _ind
	pos = _pos
	
	for e in edges:
		if e.to == index:
			inward_edges.push_back(e)
		else:
			outward_edges.push_back(e)
