extends AnimatedSprite3D
class_name BattleUnit

@export var unitData: UnitStats

var playerID: int
var teamID: int
var initMoves: Array[BattleScript]

var inputManager: InputManager
var battleController: BattleController
var hex_pos: HexVector

func initialize(cubePos: Vector2, data: Resource):
	unitData = data
	for unitMove in unitData.moveset:
		var move: BattleScript = unitMove.new()
		move.user = self
		initMoves.push_back(move)
	setLocation(HexVector.fromCubePos(cubePos))
	pass

## sets location. idk
func setLocation(hex_vec: HexVector):
	hex_pos = hex_vec
	position = HexMath.axis_to_3D(hex_vec.q, hex_vec.r)
	setAnimation("default")
	pass

func setAnimation(anim: String):
	animation = anim
	position.y = (sprite_frames.get_frame_texture(anim, 0).get_size().y * pixel_size / 2) + HexMath.HEX_HEIGHT
	pass

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true:
			if inputManager.selectorState == InputManager.InputStates.UNITS:
				pass
			if inputManager.selectorState == InputManager.InputStates.PENDING:
				inputManager.createInputs(Vector2(event.position), self)
				print(event)
				pass
	pass # Replace with function body.


func _on_mouse_entered() -> void:
	if inputManager.selectorState == InputManager.InputStates.PENDING:
		modulate = Color(0.59, 1.0, 0.59, 1.0)
		pass
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	if inputManager.selectorState == InputManager.InputStates.PENDING:
		modulate = Color(1, 1.0, 1, 1.0)
		pass
	pass # Replace with function body.
