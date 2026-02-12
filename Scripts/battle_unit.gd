extends AnimatedSprite3D
class_name BattleUnit

@export var unitData: UnitStats
@export var hpBar: ProgressBar

var stats: UnitStatLine = null

var playerID: int
var unitID: int
var teamID: int
var initMoves: Array[BattleScript]
var sight: Array[HexTile]

var inputManager: InputManager
var battleController: BattleController
var hex_pos: HexVector
var hex_height: float
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
var spriteHeight: float = 1

var _calculating_sight = false

func initialize(cubePos: Vector2, height: int, data: Resource, _unitID: int):
	unitID = _unitID
	unitData = data
	stats = UnitStatLine.new(data)
	
	for unitMove in unitData.moveset:
		var move: BattleScript = unitMove.new()
		move.user = self
		initMoves.push_back(move)
	setLocation(HexVector.fromCubePos(cubePos), height)
	pass

func isOwned():
	return (NetworkManager.steam_id == playerID)

## sets location. idk
func setLocation(hex_vec: HexVector, _height: int):
	hex_pos = hex_vec
	hex_height = _height
	setAnimation("default")
	updateSight()
	pass

func setAnimation(anim: String):
	animation = anim
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
		await move(data, 1.0/cost)
	setAnimation("default")

func jump_parabola(h0:float,h1:float,v:float, t:float):
	var b = 4*(v-h0)+h0-h1
	var c = h0
	var a = h1-h0-b
	t = clampf(t, 0, 1)
	return a*t**2+b*t+c

func move(tile: HexTile, speed_scaler: float):
	print("moving")
	setAnimation("moving")
	
	target_pos = tile.hex_pos
	var t = 0
	var original_height = hex_height
	var original_pos = hex_pos
	var parabola_scale = 0
	
	if original_height != tile.height:
		speed_scaler = 1.0/float(HexTile.JUMP_COST)
	
	while t < 1:
		hex_pos = HexVector.lerp(original_pos, tile.hex_pos, t)
		if original_height != tile.height:
			hex_height = jump_parabola(original_height, tile.height, tile.height+2, t)
		t += _delta*unitData.moveSpeed*speed_scaler
		await get_tree().create_timer(_delta).timeout
	
	updateSight()
	hex_pos = target_pos
	hex_height = tile.height
	
	
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
	var range_list = inputManager.controller.map.getHexesInRange(other.virtual_pos, range)
	return inputManager.controller.map.get_hex(hex_pos) in range_list

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

func getPosition(_hvec: HexVector, _height: float):
	var newSH =  sprite_frames.get_frame_texture(animation, frame).get_height()*pixel_size
	if newSH != spriteHeight:
		spriteHeight = newSH
		print("nSH: ", newSH)
	
	var hpos: Vector3 = HexMath.axis_to_3D(_hvec.q, _hvec.r)
	hpos.y = 0
	return hpos + Vector3(0,(_height)*Hex.TILE_HEIGHT + spriteHeight/2,0)

func updateSight(pos = hex_pos):
	if _calculating_sight:
		return
	_calculating_sight = true
	sight = await inputManager.controller.map.getSight(pos,10)
	_calculating_sight = false
	inputManager.controller.updateTeamSight(teamID)

func _process(delta: float) -> void:
	_delta = delta
	
	
	
	if hex_pos != null:
		
		position = getPosition(hex_pos, hex_height)
		
	
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
