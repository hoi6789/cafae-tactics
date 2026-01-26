class_name Heap

var nodes: Array
var compare_callback: Callable
var size = 0


func comp_maxheap(l, r):
	return (l > r)

func _init(A: Array, heap_sort=false, _compare_callback = null):
	if _compare_callback == null:
		compare_callback = comp_maxheap
	else:
		compare_callback = _compare_callback
	
	if heap_sort:
		for a in A:
			insert(a)
	else:
		nodes = A.duplicate()
		size = len(nodes)
		for i in range(floor(size/2)+1, -1, -1):
			heapify(i)

func swap(index_a: int, index_b: int):
	var temp = nodes[index_a]
	nodes[index_a] = nodes[index_b]
	nodes[index_b] = temp

func left_child(i: int) -> int:
	if 2*i+1 < size:
		return 2*i+1
	return -1

func right_child(i: int) -> int:
	if 2*i+2 < size:
		return 2*i+2
	return -1
	
func compare(l: int, r: int) -> bool: ##returns true if l should be placed before r in the heap
	return compare_callback.call(nodes[l], nodes[r])

func insert(element):
	nodes.push_front(element)
	size += 1
	heapify(0)

func heapify(i=0):
	
	var l = left_child(i)
	var r = right_child(i)
	var largest = -1
	if l != -1 and compare(l, i):
		largest = l
	else:
		largest = i
	if r != -1 and compare(r, largest):
		largest = r

	if largest != i:
		swap(i, largest)
		heapify(largest)

func extract():
	var node = nodes[0]
	nodes.remove_at(0)
	size = size-1
	heapify(0)
	return node
