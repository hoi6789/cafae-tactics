extends Control
var userState: String = "alloweda"
var selectorState: String = "none"
## none = highlight nothing, units = highlight units, hexes = highlight hexes,
var playerID: int = 1
var queueCommand: int = 0

var controller = get_parent()

func _ready() -> void:
	controller = get_parent()

func _on_summon_button_pressed() -> void:
	selectorState = "hexes"
	queueCommand = 5
	pass # Replace with function body.

func chooseHex(hex: Hex):
	match queueCommand:
		5:
			var n:Array[int] = [1]
			print(Vector3(hex.q, hex.r, hex.s))
			hex.id = 2
			controller.processInput(n)
	pass
