extends StaticBody3D
class_name Hex

const TILE_HEIGHT = 0.2

## tile data
var data: HexTile 
## 
var storedUnits = []

var baseColour: Color
var surfMaterial: Material
var surfOverlay: Material
var overlayColours: Array[Color]

var inputManager: InputManager

var highlighted: bool = false
var rangeHighlighted: bool = false
var holoHighlighted: int = 0
var hovered: bool = false


func initialize(_data: HexTile):
	## Initialization function to setup properties of a hex
	surfMaterial = $CollisionPolygon3D/MeshInstance3D.get_surface_override_material(0).duplicate(true)
	surfOverlay = surfMaterial.next_pass.next_pass
	$CollisionPolygon3D/MeshInstance3D.set_surface_override_material(0, surfMaterial)
	data = _data
	data.hex = self
	setColour(data.type)
	setPosition(HexVector.toCubePos(data.hex_pos))
	pass

func highlight():
	highlighted = true
	resetColour()

func unhighlight():
	highlighted = false
	resetColour()
	
func rangeHighlight():
	rangeHighlighted = true
	resetColour()
	
func unrangeHighlight():
	rangeHighlighted = false
	resetColour()

func resetColour():
	surfOverlay.albedo_color = Color(0, 0, 0, 0)
	if rangeHighlighted: overlayBlend(Color.GOLD, 0.5)
	if highlighted: overlayBlend(Color.CADET_BLUE, 0.5)
	if hovered: overlayBlend(Color.GREEN, 0.5)
	else:
		surfMaterial.albedo_color = baseColour

func setColour(palette: HexTile.TerrainType):
	match palette:
		HexTile.TerrainType.ROUGH: 
			baseColour = varyColour(Color(0.857, 0.338, 0.071, 0.5))
		_:
			baseColour = varyColour(Color(0.72, 0.72, 0.72, 0.50))
		
	surfMaterial.albedo_color = baseColour
	$CollisionPolygon3D/MeshInstance3D.set_surface_override_material(0, surfMaterial)
	pass

func getWorldPosition() -> Vector3:
	var xz = HexMath.axis_to_3D(data.hex_pos.q, data.hex_pos.r)
	xz += Vector3(0, data.height*TILE_HEIGHT, 0)
	return xz

func setPosition(cubePos: Vector2):
	## Hexes use "axial" coordinates described in https://www.redblobgames.com/grids/hexagons/
	## i.e. they are defined on a plane where q + r + s = 0
	data.hex_pos = HexVector.fromCubePos(cubePos)
	
	position = getWorldPosition()
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

func overlayBlend(col: Color, alpha: float):
	col.a = alpha
	surfOverlay.albedo_color = surfOverlay.albedo_color.blend(col)

func _on_mouse_entered() -> void:
	if inputManager.selectorState == InputManager.InputStates.HEXES:
		hovered = true
		#surfMaterial.albedo_color = Color(0, 1, 0, 1)
		resetColour()
		inputManager.setHoveredHex(self)
		#print(id)
	pass # Replace with function body.

func _on_mouse_exited() -> void:
	if inputManager.selectorState == InputManager.InputStates.HEXES:
		hovered = false
		resetColour()
		inputManager.unsetHoveredHex(self)
	pass # Replace with function body.


func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true and inputManager.selectorState == InputManager.InputStates.HEXES:
			inputManager.chooseHex(self)
			_on_mouse_exited()
			inputManager.setInputState(InputManager.InputStates.PENDING)
			pass
	pass # Replace with function body.
