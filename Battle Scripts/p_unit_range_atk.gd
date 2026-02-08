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
	
func execute(controller: BattleController):
	var bul = load("res://Prefabs/bullet.tscn").instantiate()
	controller.addProjectile(bul)
	bul.initialize(user, controller.getUnit(data[0]), self)
	pass

func onHit(controller: BattleController):
	launchMeleeAttack(controller)
