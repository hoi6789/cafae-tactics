class_name PolyMath

static func smooth(t):
	return 3*t**2 - 2*t**3

static func PointInPoly(p: Vector2, polygon: Array[Vector2]):
	var n = len(polygon)
	var intersectionCount = 0
	for i in range(n):
		var p0 = polygon[i]
		var p1 = polygon[(i+1)%n]
		
		if p.y > min(p0.y, p1.y) and p.y <= max(p0.y, p1.y) and p.x <= max(p0.x, p1.x):
			var xInt = (p.y - p0.y)*(p1.x - p0.x)/(p1.y - p0.y) + p0.x
			if p0.x == p1.x or p.x <= xInt:
				intersectionCount += 1
	
	return intersectionCount%2 == 1
