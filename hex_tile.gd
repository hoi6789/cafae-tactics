extends StaticBody3D
var id = 0
var q: float = 0
var r: float = 0
var s: float = 0

var type: String = "default"
var baseColour: Color
var surfMaterial

func initialize(cubePos: Vector2, _type: String):
	## Initialization function to setup properties of a hex
	surfMaterial = $CollisionPolygon3D/MeshInstance3D.get_surface_override_material(0).duplicate(true)
	type = _type
	setColour(_type)
	setPosition(cubePos)
	pass

func setColour(palette: String):
	match palette:
		_:
			baseColour = Color(0.825 + cRand(), 0.209 + cRand(), 0.969 + cRand(), 1.0)
	
	surfMaterial.albedo_color = baseColour
	$CollisionPolygon3D/MeshInstance3D.set_surface_override_material(0, surfMaterial)
	pass

func setPosition(cubePos: Vector2):
	## Hexes use "axial" coordinates described in https://www.redblobgames.com/grids/hexagons/
	## i.e. they are defined on a plane where q + r + s = 0
	q = cubePos.x
	r = cubePos.y
	s = 0 - q - r
	
	## multiplies by q/r basis vectors to determine position of the hex in world coords
	var offset_q = q / 2 * Vector3(sqrt(3), 0, 0)
	var offset_r = r / 2 * Vector3(sqrt(3)/2, 0, 1.5)
	
	position = offset_q + offset_r
	print(position)
	pass

func cRand():
	return (randf() * 0.2) - 0.1

func _on_mouse_entered() -> void:
	surfMaterial.albedo_color = Color(0, 1, 0, 1)
	$CollisionPolygon3D/MeshInstance3D.set_surface_override_material(0, surfMaterial)
	print(id)
	pass # Replace with function body.

func _on_mouse_exited() -> void:
	surfMaterial.albedo_color = baseColour
	$CollisionPolygon3D/MeshInstance3D.set_surface_override_material(0, surfMaterial)
	pass # Replace with function body.
