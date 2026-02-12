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
const FOW_TINT: float = 0.2
var tint = FOW_TINT

var inputManager: InputManager

var highlighted: bool = false
var rangeHighlighted: bool = false
var holoHighlighted: int = 0
var hovered: bool = false
var can_see = false
var tint_anim_active = false
var global_tint_targ = 1


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

func setTint(targ: float, _duration: float = 1.0):
	global_tint_targ = targ
	if tint_anim_active:
		return
	tint_anim_active = true
	var timer: Timer = Timer.new()
	add_child(timer)
	var orig = tint
	var t = 0
	while t < 1:
		tint = orig + (targ - orig)*PolyMath.smooth(t)
		tint = clamp(tint, 0, 1)

		resetColour()
		var dt = 1.0/Engine.get_frames_per_second()
		timer.start(dt)
		await timer.timeout
		t += dt/_duration
		if targ != global_tint_targ:
			targ = global_tint_targ
			t = 0
			orig = tint
	tint_anim_active = false
	timer.queue_free()

func setSight(_can_see: bool):
	can_see = _can_see
	setTint(1 if can_see else FOW_TINT, 0.075)
	resetColour()
		

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

func getTintFactor():
	return tint

func resetColour():
	surfOverlay.albedo_color = Color(0, 0, 0, 0)
	if rangeHighlighted: overlayBlend(Color.GOLD, 0.5)
	if highlighted: overlayBlend(Color.CADET_BLUE, 0.5)
	if hovered: overlayBlend(Color.GREEN, 0.5)
	else:
		surfMaterial.albedo_color = baseColour*getTintFactor()

func setColour(palette: HexTile.TerrainType):
	match palette:
		HexTile.TerrainType.ROUGH: 
			baseColour = varyColour(Color(0.857, 0.338, 0.071, 0.5))
		_:
			baseColour = varyColour(Color(0.72, 0.72, 0.72, 0.50))
		
	surfMaterial.albedo_color = baseColour*getTintFactor()
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
