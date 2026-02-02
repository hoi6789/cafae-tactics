extends AnimatedSprite3D
class_name BattleUnit

@export var unitData: UnitStats
@export var hpBar: ProgressBar

var stats: UnitStatLine = null

var playerID: int
var unitID: int
var teamID: int
var initMoves: Array[BattleScript]

var inputManager: InputManager
var battleController: BattleController
var hex_pos: HexVector
var target_pos: HexVector
var _delta = 0
var last_position: Vector3 
var windupTimer: float = 0
var windupInterrupted: bool = true

var hovering = false
var hpAnimTimer = 0
var oldHpVal = 0
var hpTarget = 0

func initialize(cubePos: Vector2, data: Resource, _unitID: int):
	unitID = _unitID
	unitData = data
	stats = UnitStatLine.new(data)
	
	for unitMove in unitData.moveset:
		var move: BattleScript = unitMove.new()
		move.user = self
		initMoves.push_back(move)
	setLocation(HexVector.fromCubePos(cubePos))
	pass

func isOwned():
	return (NetworkManager.steam_id == playerID)

## sets location. idk
func setLocation(hex_vec: HexVector):
	hex_pos = hex_vec
	setAnimation("default")
	pass

func setAnimation(anim: String):
	animation = anim
	position.y = (sprite_frames.get_frame_texture(anim, 0).get_size().y * pixel_size / 2) + HexMath.HEX_HEIGHT
	pass

func movePath(path: Array[HexTile]):
	for data in path:
		await move(data.hex_pos)
	setAnimation("default")

func move(pos: HexVector):
	setAnimation("moving")
	target_pos = pos
	var t = 0
	var original_pos = hex_pos
	
	while t < 1:
		hex_pos = HexVector.lerp(original_pos, pos, t)
		t += _delta*unitData.moveSpeed
		await get_tree().create_timer(_delta).timeout
	hex_pos = pos

func waitWindup(duration: float):
	setAnimation("windup")
	windupTimer = 0
	while windupTimer < duration: ## THIS IS LIKE THIS TO IMPLEMENT ANTI-LAG SUPER ARMOR
		windupTimer += _delta
		await get_tree().create_timer(_delta).timeout
	pass

func dealDamage(dmg: int, target: BattleUnit):
	target.receiveDamage(dmg, self)
	setAnimation("attacking")

func receiveDamage(dmg: int, attacker: BattleUnit):
	setAnimation("hitstun")
	windupTimer = 0
	stats.hp -= UnitStats.DamageFormula(dmg, unitData)
	if stats.hp < 0:
		stats.hp = 0

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true:
			if inputManager.selectorState == InputManager.InputStates.UNITS:
				inputManager.chooseUnit(self)
				pass
			if inputManager.selectorState == InputManager.InputStates.PENDING and isOwned():
				inputManager.createInputs(Vector2(event.position), self)
				print(event)
				pass
	pass # Replace with function body.


func _on_mouse_entered() -> void:
	hovering = true
	if inputManager.selectorState == InputManager.InputStates.PENDING:
		modulate = Color(0.59, 1.0, 0.59, 1.0)
		inputManager.setHoveredUnit(self)
		pass
	if inputManager.selectorState == InputManager.InputStates.UNITS:
		modulate = Color(0.59, 1.0, 0.59, 1.0)
		inputManager.setHoveredUnit(self)
		pass
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	hovering = false
	if inputManager.selectorState == InputManager.InputStates.PENDING:
		modulate = Color(1, 1.0, 1, 1.0)
		pass
	pass # Replace with function body.

func _process(delta: float) -> void:
	_delta = delta
	if hex_pos != null:
		var y = position.y
		position = HexMath.axis_to_3D(hex_pos.q, hex_pos.r)
		position.y = y
	
	if last_position != position:
		var tranform_matrix = get_viewport().get_camera_3d().global_transform.affine_inverse()
		var cube_start = tranform_matrix * last_position
		var cube_end = tranform_matrix * position
		var screen_vel = cube_end - cube_start
		if screen_vel.x != 0:
			flip_h = (screen_vel.x > 0)
	
	last_position = position		
	
	#UI
	hpBar.visible = (isOwned() || hovering)
	if stats != null:
		var hpFrac = float(stats.hp)/float(stats.maxHP)
		if abs(hpTarget - hpFrac) > 0.005:
			oldHpVal = hpTarget
			hpTarget = hpFrac
			hpAnimTimer = 0
			
		if hpAnimTimer < 1:
			hpAnimTimer += delta*2
		var prog: float = sin(0.5*PI*(hpAnimTimer**0.75))
		hpBar.value = lerp(float(oldHpVal), float(hpTarget), prog)
