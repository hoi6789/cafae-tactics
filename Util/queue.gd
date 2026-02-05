class_name  Queue

var data: Array = []
var size = 0

func push(x) -> void:
	data.push_back(x)
	size += 1

func pop():
	var d = data[0]
	size -= 1
	data.remove_at(0)
	return d
