extends AnimatedSprite3D
class_name BattleUnit

@export var unitData: UnitStats

var player: int
var team: int
var initMoves: Array[Node3D]

var inputManager: InputManager
var battleController: BattleController

func initialize(cubePos: Vector2, data: Resource):
	unitData = data
	for move in unitData.moveset:
		var mychild: Node3D = Node3D.new()
		mychild.set_script(move)
		mychild.name = mychild.moveName
		add_child(mychild)
		initMoves.push_back(mychild)
		print(get_children())
	setLocation(cubePos.x, cubePos.y)
	pass

## sets location. idk
func setLocation(q, r):
	position = HexMath.axis_to_3D(q, r)
	setAnimation("default")
	pass

func setAnimation(anim: String):
	animation = anim
	position.y = (sprite_frames.get_frame_texture(anim, 0).get_size().y * pixel_size / 2) + HexMath.HEX_HEIGHT
	pass

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true and inputManager.selectorState == InputManager.InputStates.UNITS:
			inputManager.createInputs(Vector2(event.position), initMoves)
			print(event)
			_on_mouse_exited()
			pass
	pass # Replace with function body.


func _on_mouse_entered() -> void:
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	pass # Replace with function body.
