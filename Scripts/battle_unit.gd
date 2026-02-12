extends FieldEntity
class_name BattleUnit

@export var unitData: UnitStats
@export var hpBar: ProgressBar

var stats: UnitStatLine = null


var initMoves: Array[BattleScript]



var battleController: BattleController
var effective_pos: HexVector

var windupTimer: float = 0
var windupInterrupted: bool = true

var hovering = false
var hpAnimTimer = 0
var oldHpVal = 0
var hpTarget = 0
var baseColour = Color.WHITE
var inputs: Array[Array] = []




func initialize(cubePos: Vector2, height: int, data: Resource, _unitID: int):
	unitID = _unitID
	unitData = data
	stats = UnitStatLine.new(data)
	sightRange = 10
	
	for unitMove in unitData.moveset:
		var move: BattleScript = unitMove.new()
		move.user = self
		initMoves.push_back(move)
	setLocation(HexVector.fromCubePos(cubePos), height)
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





func _process(delta: float) -> void:
	update(delta)
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
