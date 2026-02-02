extends BattleScript

func _init() -> void:
	moveName = "Generic Ranged Attack"
	desc = "Hits a unit at long range. Genuinely what else would it do"
	inputScheme = InputManager.InputStates.UNITS
	inputValidation = InputManager.ValidationStates.ALL
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
	var dmg = user.unitData.attack
	controller.units[data[0]].receiveDamage(dmg, user)
	pass
