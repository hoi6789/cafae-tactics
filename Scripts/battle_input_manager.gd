extends Control
class_name InputManager

@export var actionsPanel: PanelContainer
@export var vboxContainer: VBoxContainer

var inputQueue = []

var done = 0
var players = 1
var doneTurn = false

var userState: String = "alloweda"
var selectorState: int = InputStates.UNITS
enum InputStates {
	NONE,
	UNITS,
	HEXES,
}
## none = highlight nothing, units = highlight units, hexes = highlight hexes,
var playerID: int = 1
var queueCommand: int = 0

var CURRENT_INPUT_HEADER = 0

var controller: BattleController = get_parent()

func _ready() -> void:
	controller = get_parent()
	players = 1 if !NetworkManager.connected else NetworkManager.player_count

func _on_summon_button_pressed() -> void:
	selectorState = InputStates.HEXES
	queueCommand = 5
	pass # Replace with function body.

func chooseHex(hex: Hex):
	match queueCommand:
		5:
			var n: Array[int] = [BattleController.Command.SUMMON, hex.q, hex.r, 1]
			print(Vector3(hex.q, hex.r, hex.s))
			hex.id = 2
			addInput(n)
	pass

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

func createInputs(pos: Vector2, moves: Array[Node3D]):
	actionsPanel.position = pos
	for child in vboxContainer.get_children():
		vboxContainer.remove_child(child)
		child.queue_free()
	for move in moves:
		var newButton: Button = Button.new()
		newButton.text = move.name
		vboxContainer.add_child(newButton)
		print(move.name)
	actionsPanel.size = Vector2(0, 0)


func _on_end_turn_button_pressed() -> void:
	endTurn()
