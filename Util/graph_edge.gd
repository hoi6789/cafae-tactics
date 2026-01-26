class_name BFSEdge

var weight: float
var from: int
var to: int

func _init(w, f, t):
	weight = w
	from = f
	to = t
	
func toString() -> String:
	return "{"+str(from)+"->"+str(to)+", "+str(weight)+"}"

static func print_path(v: Array):
	for edge in v:
		print(edge.toString())
