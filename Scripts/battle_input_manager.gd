extends Control
class_name InputManager

signal selected
static var instance: InputManager

@export var actionsPanel: Panel
@export var vboxContainer: VBoxContainer
@export var doneTurnButton: Button
@export var actionsView: VBoxContainer
var loadedLabel: Label

var inputQueue = []

var done = 0
var players = 1
var doneTurn = false

var userState: String = "alloweda"
var selectorState: int = InputStates.PENDING
var validationState: int = ValidationStates.ALL
var executingInputs = false
var inputRange = INF

enum ActionState {
	NONE,
	CANCEL,
	FINISH
}

var actionState: ActionState


## none = highlight nothing, pending = waiting for input, units = highlight units, hexes = highlight hexes,
enum InputStates {
	DISABLED,
	PENDING,
	CONFIRMATION,
	UNITS,
	HEXES,
}

enum ValidationStates {
	ALL,
	ALLIES,
	ENEMIES
}

var playerID: int = 1
var teamID: int = 1
var queueCommand: int = 0

var selectedUnit: BattleUnit
var hoveredUnit: BattleUnit
var selectedHex: Hex
var hoveredHex: Hex

var CURRENT_INPUT_HEADER = 0

var controller: BattleController = get_parent()
var scriptAtlas: ScriptAtlas

var last_shape: Array[Vector2] = []
var drawY = 0.5
func draw3d():
	for i in range(len(last_shape)):
		var p0 = last_shape[i]
		var p1 = last_shape[(i+1)%len(last_shape)]
		DebugDraw3D.draw_line(Vector3(p0.x,drawY,p0.y),Vector3(p1.x,drawY,p1.y))
	pass


func _ready() -> void:
	scriptAtlas = load("res://Resources/Script_Atlas.tres")
	controller = get_parent()
	players = 1 if !NetworkManager.connected else NetworkManager.player_count
	instance = self

func _on_summon_button_pressed() -> void:
	setInputState(InputStates.HEXES)
	queueCommand = 5
	pass # Replace with function body.

func chooseHex(hex: Hex):
	match queueCommand:
		5:
			var n: Array[int] = [BattleController.Command.SUMMON_UNIT, hex.data.hex_pos.q, hex.data.hex_pos.r, hex.data.height, 1, NetworkManager.steam_id, BattleController.playerTeam]
			print(Vector3(hex.data.hex_pos.q, hex.data.hex_pos.r, hex.data.hex_pos.s))
			#hex.id = 2
			addInput(n)
		0: 
			selectedHex = hex
			#controller.highlightPath(await controller.map.getShortestPath(controller.map.get_hex(selectedUnit.hex_pos), controller.map.get_hex(hex.data.hex_pos)))
	actionState = ActionState.NONE
	selected.emit()
	pass

func chooseUnit(unit: BattleUnit):
	match validationState:
		ValidationStates.ALL:
			pass
		ValidationStates.ALLIES:
			# if unit.team not same as first unit's team then return null
			if unit.teamID != BattleController.playerTeam:
				return null
			pass
		ValidationStates.ENEMIES:
			if unit.teamID == BattleController.playerTeam:
				return null
			pass
	selectedUnit = unit
	setInputState(InputManager.InputStates.PENDING)
	selected.emit()
	pass

func createInputs(pos: Vector2, unit: BattleUnit):
	actionsPanel.position = pos + Vector2(5, 5)
	selectedUnit = unit
	var maxWidth: float = 0
	var maxHeight: float = 0
	var maxSize: Vector2
	for child in vboxContainer.get_children():
		vboxContainer.remove_child(child)
		child.queue_free()
	for move in unit.initMoves:
		var newButton: Button = Button.new()
		newButton.text = move.moveName
		newButton.set_meta("move", move)
		newButton.pressed.connect(actionButtonPressed.bind(move))
		newButton.mouse_entered.connect(actionButtonHovered.bind(move, newButton))
		vboxContainer.add_child(newButton)
		print(move.moveName)
		maxWidth = max(newButton.size.x, maxWidth)
		maxHeight += newButton.size.y + vboxContainer.get_theme_constant("separation")
	maxHeight -= vboxContainer.get_theme_constant("separation")
	maxSize = Vector2(maxWidth, maxHeight)
	print(maxSize)
	%TooltipPanel.position = Vector2(maxWidth, 0)
	%TooltipPanel.size = Vector2(200, maxHeight)
	actionsPanel.size = maxSize
	actionsPanel.visible = true
	

func actionButtonPressed(move: BattleScript):
	if !move.user.isOwned():
		return
	actionsPanel.visible = false
	await move.selection_logic(self)
	if actionState != InputManager.ActionState.CANCEL:
		var	input = [controller.Command.SCRIPT, move.user.unitID, scriptAtlas.get_id(move)] + move.data
		var n: Array[int]
		move.user.inputs.push_back(n)
		n.assign(input)
		addInput(n)
		
		var actionLabel: Label = Label.new()
		actionLabel.text = "Unit ID " + str(move.user.unitID) + " using action " + move.moveName + " with data " + str(move.data)
		actionLabel.horizontal_alignment =HORIZONTAL_ALIGNMENT_RIGHT
		actionLabel.autowrap_mode =TextServer.AUTOWRAP_WORD_SMART
		actionLabel.mouse_filter = Control.MOUSE_FILTER_PASS
		actionLabel.set_meta("user", move.user)
		actionLabel.set_meta("userMove", move.user.inputs[-1])
		actionLabel.set_meta("globalMove", inputQueue[-1])
		actionLabel.set_meta("id", inputQueue.size())
		actionLabel.mouse_entered.connect(actionLabelHovered.bind(actionLabel))
		actionLabel.mouse_exited.connect(actionLabelUnhovered.bind(actionLabel))
		actionsView.add_child(actionLabel)
	setInputState(InputManager.InputStates.PENDING)
	move.user.updateVirtualPosition()

func actionButtonHovered(move: BattleScript, button: Button):
	%TooltipPanel/Title.text = move.moveName
	%TooltipPanel.size.x = button.size.x
	
func actionLabelHovered(label: Label):
	label.modulate = Color(1, 0, 0)
	loadedLabel = label
	pass
	
func actionLabelUnhovered(label: Label):
	label.modulate = Color(1, 1, 1)
	loadedLabel = null
	pass

func setHoveredHex(hex: Hex):
	hoveredHex = hex
	if selectedUnit != null:
		pass#controller.highlightPath(controller.map.getShortestPath(controller.map.get_hex(selectedUnit.hex_pos),hex.data))
	
func unsetHoveredHex(hex: Hex):
	if hoveredHex == hex:
		hoveredHex = null

func setHoveredUnit(unit: BattleUnit):
	hoveredUnit = unit
	
func unsetHoveredUnit(unit: BattleUnit):
	if hoveredUnit == unit:
		hoveredUnit.modulate = Color(1, 1, 1)
		hoveredUnit = null

func _on_end_turn_button_pressed() -> void:
	endTurn()

func setInputState(state: InputStates):
	selectorState = state
	$StateLabel.text = "Input State: " + InputStates.keys()[state]
	print("setting state: ", InputStates.keys()[state])
	if state != InputStates.PENDING:
		doneTurnButton.disabled = true
	else:
		doneTurnButton.disabled = false
	
	
	for unit in controller.units:
		unit.updateModulation()
	
func setValidationState(state: ValidationStates):
	validationState = state
	$StateLabel.text += " (" + ValidationStates.keys()[state] + ")"

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true:
			if selectorState == InputStates.PENDING:
				print("l")
				actionsPanel.visible = false
				pass
			if loadedLabel:
				for label in actionsView.get_children():
					if label.get_meta("id") >= loadedLabel.get_meta("id") and label.get_meta("user") == loadedLabel.get_meta("user"):
						removeInput(label.get_meta("globalMove"))
						label.get_meta("user").inputs.erase(label.get_meta("userMove"))
						label.get_meta("user").updateVirtualPosition()
						label.queue_free()
	pass # Replace with function body.


func addInput(n: Array[int]):
	if NetworkManager.connected:
		rpc_pushInput.rpc(n)
	else:
		rpc_pushInput(n)

@rpc("any_peer","call_local")
func rpc_pushInput(n: Array[int]):
	inputQueue.push_back(n)

func removeInput(n: Array[int]):
	if NetworkManager.connected:
		rpc_pushInput.rpc(n)
	else:
		rpc_deleteInput(n)

@rpc("any_peer","call_local")
func rpc_deleteInput(n: Array[int]):
	inputQueue.erase(n)

func resetTurnStatus():
	doneTurn = false
	done = 0
	doneTurnButton.disabled = false
	selectorState = InputStates.PENDING
	for unit: BattleUnit in controller.units:
		unit.resetForNewTurn()

func executeInputChain(inputArr: Array):
	for input in inputArr:
		await controller.processInput(input) 

func executeInputs():
	for child in actionsView.get_children():
		child.queue_free()
	executingInputs = true
	controller.removeHighlights()
	controller.activeInputs = len(inputQueue)
	print(inputQueue)
	var inputChannel: Dictionary[int, Array] = {}
	for input in inputQueue:
		print("running: ", input)
		if input[0] == BattleController.Command.SUMMON_UNIT:
			controller.processInput(input)
		else:
			if input[1] not in inputChannel:
				inputChannel[input[1]] = []
			
			inputChannel[input[1]].push_back(input)
		
	for inputChain in inputChannel.values():
		executeInputChain(inputChain)
	while controller.activeInputs > 0:
		await get_tree().process_frame
	if controller.projectiles.size() > 0:
		await controller.projectilesGone
	inputQueue = []
	resetTurnStatus()
	executingInputs = false

func endTurn():
	if doneTurn:
		return
	selectorState = InputStates.DISABLED
	doneTurnButton.disabled = true
	doneTurn = true
	if NetworkManager.connected:
		rpc_finishTurn.rpc()
	else:
		rpc_finishTurn()

@rpc("any_peer","call_local")
func rpc_finishTurn():
	done += 1
	print(inputQueue)
	if done == players:
		executeInputs()

func _process(delta: float) -> void:
	#draw3d()
	if Input.is_action_just_pressed("cancel_action"):
		actionState = ActionState.CANCEL
		selected.emit()
		if hoveredUnit != null:
			unsetHoveredUnit(hoveredUnit)
	if Input.is_action_just_pressed("finish_action"):
		actionState = ActionState.FINISH
		selected.emit()
		if hoveredUnit != null:
			unsetHoveredUnit(hoveredUnit)
