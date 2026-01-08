extends StaticBody3D
var id = 0
var q: float = 0
var r: float = 0
var s: float = 0

func setPosition(cubePos: Vector2):
	q = cubePos.x
	r = cubePos.y
	s = 0 - q - r
	
	var offset_q = q / 2 * Vector3(sqrt(3), 0, 0)
	var offset_r = r / 2 * Vector3(sqrt(3)/2, 0, 1.5)
	
	position = offset_q + offset_r
	print(position)
	pass

func _on_mouse_entered() -> void:
	var newSurface = $CollisionPolygon3D/MeshInstance3D.get_surface_override_material(0).duplicate(true)
	newSurface.albedo_color = Color(0, 1, 0, 1)
	$CollisionPolygon3D/MeshInstance3D.set_surface_override_material(0, newSurface)
	print(id)
	pass # Replace with function body.



func _on_mouse_exited() -> void:
	$CollisionPolygon3D/MeshInstance3D.get_surface_override_material(0).albedo_color = Color(1, 0, 0, 1)
	pass # Replace with function body.
