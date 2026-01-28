extends Control
class_name InputManager

@export var actionsPanel: PanelContainer
@export var vboxContainer: VBoxContainer

var inputQueue = []

var done = 0
var players = 1
var doneTurn = false

var userState: String = "alloweda"
var selectorState: int = InputStates.PENDING

## none = highlight nothing, pending = waiting for input, units = highlight units, hexes = highlight hexes,
enum InputStates {
	DISABLED,
	PENDING,
	UNITS,
	HEXES,
}

var playerID: int = 1
var queueCommand: int = 0

var selectedUnit: BattleUnit

var CURRENT_INPUT_HEADER = 0

var controller: BattleController = get_parent()

func _ready() -> void:
	controller = get_parent()
	players = 1 if !NetworkManager.connected else NetworkManager.player_count

func _on_summon_button_pressed() -> void:
	setInputState(InputStates.HEXES)
	queueCommand = 5
	pass # Replace with function body.

func chooseHex(hex: Hex):
	match queueCommand:
		5:
			var n: Array[int] = [BattleController.Command.SUMMON, hex.data.hex_pos.q, hex.data.hex_pos.r, 1]
			print(Vector3(hex.data.hex_pos.q, hex.data.hex_pos.r, hex.data.hex_pos.s))
			#hex.id = 2
			addInput(n)
		0: 
			controller.highlightPath(controller.map.getShortestPath(controller.map.get_hex(selectedUnit.hex_pos), controller.map.get_hex(hex.data.hex_pos)))
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
		newButton.text = move.name
		newButton.set_meta("move", move)
		newButton.pressed.connect(actionButtonPressed.bind(move))
		vboxContainer.add_child(newButton)
		print(move.name)
	actionsPanel.size = Vector2(0, 0)

func actionButtonPressed(move: BattleScript):
	actionsPanel.visible = false
	setInputState(move.inputScheme)
	pass

func _on_end_turn_button_pressed() -> void:
	endTurn()

func setInputState(state: InputStates):
	selectorState = state
	$StateLabel.text = "Input State: " + InputStates.keys()[state]
	pass

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
	
func executeInputs():
	for input in inputQueue:
		print("running: ", input)
		controller.processInput(input)

func endTurn():
	if doneTurn:
		return
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
