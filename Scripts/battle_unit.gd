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
var virtual_pos: HexVector
var effective_pos: HexVector
var target_pos: HexVector
var _delta = 0
var last_position: Vector3 
var windupTimer: float = 0
var windupInterrupted: bool = true

var hovering = false
var hpAnimTimer = 0
var oldHpVal = 0
var hpTarget = 0
var baseColour = Color.WHITE
var inputs: Array[Array] = []

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

func getVirtualPosition() -> HexVector: ##returns predicted position after applying all inputs 
	var pos = hex_pos.copy()
	for input in inputs:
		pos = inputManager.controller.inputToScript(input)._transformVirtualPosition(inputManager, pos)
	return pos

func updateVirtualPosition() -> void:
	virtual_pos = getVirtualPosition()

func resetForNewTurn() -> void:
	inputs = []
	updateVirtualPosition()

func movePath(path: Array[HexTile]):
	var lastTile = inputManager.controller.map.get_hex(hex_pos)
	for data in path:
		var cost: float = 1
		if lastTile != null:
			cost = inputManager.controller.map.getIntermovementCost(lastTile, data)
		lastTile = data
		await move(data.hex_pos, 1.0/cost)
	setAnimation("default")

func move(pos: HexVector, speed_scaler: float):
	setAnimation("moving")
	target_pos = pos
	var t = 0
	var original_pos = hex_pos
	
	while t < 1:
		hex_pos = HexVector.lerp(original_pos, pos, t)
		t += _delta*unitData.moveSpeed*speed_scaler
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
	await get_tree().create_timer(0.5).timeout

func receiveDamage(dmg: int, attacker: BattleUnit):
	setAnimation("hitstun")
	windupTimer = 0
	stats.hp -= UnitStats.DamageFormula(dmg, unitData)
	if stats.hp < 0:
		stats.hp = 0

func inRange(other: BattleUnit = inputManager.selectedUnit, range: float = inputManager.inputRange) -> bool:
	return HexVector.dist(other.virtual_pos, hex_pos) <= range

func canSelect() -> bool:
	return (inputManager != null and 
	inputManager.selectorState == InputManager.InputStates.UNITS and 
	inputManager.selectedUnit != null and inputManager.selectedUnit != self and 
	inRange())

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true:
			if canSelect():
				inputManager.chooseUnit(self)
				pass
			elif inputManager.selectorState == InputManager.InputStates.PENDING and isOwned():
				effective_pos = hex_pos
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
	if canSelect():
		modulate = Color(1.0, 0.236, 0.092, 1.0)
		inputManager.setHoveredUnit(self)
		pass
	pass # Replace with function body.

func getAtk() -> float:
	return unitData.attack
	
func getDef() -> float:
	return unitData.defense

func _on_mouse_exited() -> void:
	hovering = false
	if inputManager.selectorState == InputManager.InputStates.PENDING or inputManager.selectorState == InputManager.InputStates.UNITS:
		modulate = baseColour
		pass
	pass # Replace with function body.

func updateBaseColour() -> void:
	baseColour = Color(1.0, 0.865, 0.584, 1.0) if canSelect() else Color.WHITE

func updateModulation() -> void:
	updateBaseColour()
	modulate = baseColour

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
