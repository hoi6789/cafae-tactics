extends Control
var userState: String = "alloweda"
var selectorState: String = "none"
## none = highlight nothing, units = highlight units, hexes = highlight hexes,
var playerID: int = 1
var queueCommand: int = 0


func _on_summon_button_pressed() -> void:
	selectorState = "hexes"
	queueCommand = 5
	pass # Replace with function body.

func chooseHex(hex: Hex):
	match queueCommand:
		5:
			print(Vector3(hex.q, hex.r, hex.s))
	pass
