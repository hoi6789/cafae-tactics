extends BattleScript

func _init() -> void:
	moveName = "Triple Attack"
	desc = "Hits a unit at close range 3 times."
	inputScheme = InputManager.InputStates.UNITS
	inputValidation = InputManager.ValidationStates.ALL
	windup = 0.5
	backswing = 0.5
	moveRange = 1
	
func execute(controller: BattleController):
	damage = user.getAtk()/3.0
	await launchMeleeAttack(controller)
	await launchMeleeAttack(controller)
	await launchMeleeAttack(controller)
	pass

func onHit(controller: BattleController):
	launchMeleeAttack(controller)
