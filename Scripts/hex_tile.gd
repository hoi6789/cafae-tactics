extends StaticBody3D
class_name Hex

var id = 0

## coordinates of the hex in cube space (q + r + s = 0)
var hex_pos: HexVector 

## 
var storedUnits = []

## used to determine colour and other properties (terrain?)
enum TerrainType
{
	BASIC
}
var type: TerrainType = TerrainType.BASIC
var baseColour: Color
var surfMaterial

var inputManager: InputManager

func initialize(cubePos: Vector2, _type: TerrainType = TerrainType.BASIC):
	## Initialization function to setup properties of a hex
	surfMaterial = $CollisionPolygon3D/MeshInstance3D.get_surface_override_material(0).duplicate(true)
	type = _type
	setColour(_type)
	setPosition(cubePos)
	pass

func setColour(palette: TerrainType):
	match palette:
		_:
			baseColour = varyColour(Color(0.825, 0.209, 0.969, 1.0))
	
	surfMaterial.albedo_color = baseColour
	$CollisionPolygon3D/MeshInstance3D.set_surface_override_material(0, surfMaterial)
	pass



func setPosition(cubePos: Vector2):
	## Hexes use "axial" coordinates described in https://www.redblobgames.com/grids/hexagons/
	## i.e. they are defined on a plane where q + r + s = 0
	hex_pos = HexVector.fromCubePos(cubePos)
	
	position = HexMath.axis_to_3D(hex_pos.q, hex_pos.r)
	if HexMath.FLAT_HEXES:
		rotation.y = PI/2
	print(position)
	pass

func varyColour(col: Color):
	var variance = 0.2
	col.r = col.r + ((randf() * variance) - (variance / 2))
	col.g = col.g + ((randf() * variance) - (variance / 2))
	col.b = col.b + ((randf() * variance) - (variance / 2))
	return col.clamp()

func _on_mouse_entered() -> void:
	if inputManager.selectorState == InputManager.InputStates.HEXES:
		pass
		surfMaterial.albedo_color = Color(0, 1, 0, 1)
		$CollisionPolygon3D/MeshInstance3D.set_surface_override_material(0, surfMaterial)
		#print(id)
	pass # Replace with function body.

func _on_mouse_exited() -> void:
	surfMaterial.albedo_color = baseColour
	$CollisionPolygon3D/MeshInstance3D.set_surface_override_material(0, surfMaterial)
	pass # Replace with function body.


func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true and inputManager.selectorState == InputManager.InputStates.HEXES:
			inputManager.selectorState = InputManager.InputStates.NONE
			inputManager.chooseHex(self)
			_on_mouse_exited()
			pass
	pass # Replace with function body.
