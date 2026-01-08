extends StaticBody3D
var id = 0

func _on_mouse_entered() -> void:
	$CollisionPolygon3D/MeshInstance3D.get_surface_override_material(0).albedo_color = Color(0, 1, 0, 1)
	print(id)
	pass # Replace with function body.



func _on_mouse_exited() -> void:
	$CollisionPolygon3D/MeshInstance3D.get_surface_override_material(0).albedo_color = Color(1, 0, 0, 1)
	pass # Replace with function body.
