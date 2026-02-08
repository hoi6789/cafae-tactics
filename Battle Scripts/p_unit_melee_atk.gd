extends BattleScript

func _init() -> void:
	moveName = "Generic Melee Attack"
	desc = "Hits a unit at close range. Genuinely what else would it do"
	inputScheme = InputManager.InputStates.UNITS
	inputValidation = InputManager.ValidationStates.ALL
	windup = 0.5
	backswing = 0.5
	moveRange = 1
	
func execute(controller: BattleController):
	damage = user.getAtk()
	await launchMeleeAttack(controller)
	pass

func onHit(controller: BattleController):
	launchMeleeAttack(controller)
