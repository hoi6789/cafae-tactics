extends Control
class_name InputManager

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

var controller = get_parent()

func _ready() -> void:
	controller = get_parent()

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
			controller.processInput(n)
	pass

func createInputs(pos: Vector2):
	$PanelContainer.position = pos
