extends BattleScript

func _init() -> void:
	moveName = "Generic Ranged Attack"
	desc = "Hits a unit at long range. Genuinely what else would it do"
	inputScheme = InputManager.InputStates.UNITS
	inputValidation = InputManager.ValidationStates.ENEMIES
	windup = 1.5
	backswing = 0.5
	moveRange = 3
	damage = 1

func selection_logic(manager: InputManager):
	manager.setInputState(inputScheme)
	manager.setValidationState(inputValidation)
	await manager.selected
	data = [manager.selectedUnit.unitID]
	pass
	
func execute(controller: BattleController):
	var bul = load("res://Prefabs/bullet.tscn").instantiate()
	controller.add_child(bul)
	bul.initialize(user, controller.getUnit(data[0]), self)
	pass
