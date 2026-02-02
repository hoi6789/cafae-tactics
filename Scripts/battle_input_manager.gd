extends Control
class_name InputManager

signal selected
static var instance: InputManager

@export var actionsPanel: PanelContainer
@export var vboxContainer: VBoxContainer
@export var doneTurnButton: Button

var inputQueue = []

var done = 0
var players = 1
var doneTurn = false

var userState: String = "alloweda"
var selectorState: int = InputStates.PENDING
var validationState: int = ValidationStates.ALL
var executingInputs = false

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
			var n: Array[int] = [BattleController.Command.SUMMON, hex.data.hex_pos.q, hex.data.hex_pos.r, 1, NetworkManager.steam_id, BattleController.playerTeam]
			print(Vector3(hex.data.hex_pos.q, hex.data.hex_pos.r, hex.data.hex_pos.s))
			#hex.id = 2
			addInput(n)
		0: 
			selectedHex = hex
			controller.highlightPath(controller.map.getShortestPath(controller.map.get_hex(selectedUnit.hex_pos), controller.map.get_hex(hex.data.hex_pos)))
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
	actionsPanel.visible = true
	actionsPanel.position = pos
	selectedUnit = unit
	for child in vboxContainer.get_children():
		vboxContainer.remove_child(child)
		child.queue_free()
	for move in unit.initMoves:
		var newButton: Button = Button.new()
		newButton.text = move.moveName
		newButton.set_meta("move", move)
		newButton.pressed.connect(actionButtonPressed.bind(move))
		vboxContainer.add_child(newButton)
		print(move.moveName)
	actionsPanel.size = Vector2(0, 0)

func actionButtonPressed(move: BattleScript):
	if !move.user.isOwned():
		return
	actionsPanel.visible = false
	await move.selection_logic(self)
	if actionState != InputManager.ActionState.CANCEL:
		var	input = [controller.Command.SCRIPT, move.user.unitID, scriptAtlas.get_id(move)] + move.data
		var n: Array[int]
		n.assign(input)
		addInput(n)
	setInputState(InputManager.InputStates.PENDING)
	
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
	if state != InputStates.PENDING:
		doneTurnButton.disabled = true
	else:
		doneTurnButton.disabled = false
	
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
	pass # Replace with function body.


func addInput(n: Array[int]):
	if NetworkManager.connected:
		rpc_pushInput.rpc(n)
	else:
		rpc_pushInput(n)

@rpc("any_peer","call_local")
func rpc_pushInput(n: Array[int]):
	inputQueue.push_back(n)

func resetTurnStatus():
	doneTurn = false
	done = 0
	doneTurnButton.disabled = false

func executeInputs():
	executingInputs = true
	controller.removeHighlights()
	controller.activeInputs = len(inputQueue)
	for input in inputQueue:
		print("running: ", input)
		controller.processInput(input)
	while controller.activeInputs > 0:
		await get_tree().process_frame
	inputQueue = []
	resetTurnStatus()
	executingInputs = false

func endTurn():
	if doneTurn:
		return
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
	if Input.is_action_just_pressed("cancel_action"):
		actionState = ActionState.CANCEL
		selected.emit()
		unsetHoveredUnit(hoveredUnit)
	if Input.is_action_just_pressed("finish_action"):
		actionState = ActionState.FINISH
		unsetHoveredUnit(hoveredUnit)
		selected.emit()
