extends StaticBody3D
class_name Hex

## tile data
var data: HexTile 
## 
var storedUnits = []

## used to determine colour and other properties (terrain?)

var baseColour: Color
var surfMaterial

var inputManager: InputManager
var highlighted: bool = false

func initialize(_data: HexTile):
	## Initialization function to setup properties of a hex
	surfMaterial = $CollisionPolygon3D/MeshInstance3D.get_surface_override_material(0).duplicate(true)
	data = _data
	data.hex = self
	setColour(data.type)
	setPosition(HexVector.toCubePos(data.hex_pos))
	pass

func highlight():
	#surfMaterial.albedo_color = Color.CADET_BLUE
	highlighted = true
	resetColour()
	#baseColour = surfMaterial.albedo_color
func unhighlight():
	highlighted = false
	resetColour()

func resetColour():
	if highlighted:
		surfMaterial.albedo_color = Color.CADET_BLUE
	else:
		surfMaterial.albedo_color = baseColour

func setColour(palette: HexTile.TerrainType):
	match palette:
		_:
			baseColour = varyColour(Color(0.737, 0.737, 0.737, 0.5))
		
	surfMaterial.albedo_color = baseColour
	$CollisionPolygon3D/MeshInstance3D.set_surface_override_material(0, surfMaterial)
	pass

func setPosition(cubePos: Vector2):
	## Hexes use "axial" coordinates described in https://www.redblobgames.com/grids/hexagons/
	## i.e. they are defined on a plane where q + r + s = 0
	data.hex_pos = HexVector.fromCubePos(cubePos)
	
	position = HexMath.axis_to_3D(data.hex_pos.q, data.hex_pos.r)
	if HexMath.FLAT_HEXES:
		rotation.y = PI/2
	print(position)
	pass

func varyColour(col: Color, hue_deviation = 0.1):
	var variance = 0.2
	var base = randf()
	col.r = col.r + ((clamp(base + hue_deviation*randf(), 0, 1) * variance) - (variance / 2))
	col.g = col.g + ((clamp(base + hue_deviation*randf(), 0, 1) * variance) - (variance / 2))
	col.b = col.b + ((clamp(base + hue_deviation*randf(), 0, 1) * variance) - (variance / 2))
	return col.clamp()

func _on_mouse_entered() -> void:
	if inputManager.selectorState == InputManager.InputStates.HEXES:
		surfMaterial.albedo_color = Color(0, 1, 0, 1)
		$CollisionPolygon3D/MeshInstance3D.set_surface_override_material(0, surfMaterial)
		inputManager.setHoveredHex(self)
		#print(id)
	pass # Replace with function body.

func _on_mouse_exited() -> void:
	if inputManager.selectorState == InputManager.InputStates.HEXES:
		resetColour()
		$CollisionPolygon3D/MeshInstance3D.set_surface_override_material(0, surfMaterial)
		inputManager.unsetHoveredHex(self)
	pass # Replace with function body.


func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true and inputManager.selectorState == InputManager.InputStates.HEXES:
			inputManager.setInputState(InputManager.InputStates.PENDING)
			surfMaterial.albedo_color = baseColour
			inputManager.chooseHex(self)
			_on_mouse_exited()
			pass
	pass # Replace with function body.
