extends BattleScript

func _init() -> void:
	moveName = "Generic Ranged Attack"
	desc = "Hits a unit at long range. Genuinely what else would it do"
	inputScheme = InputManager.InputStates.UNITS
	windup = 2500
	backswing = 500
	moveRange = 3
	damage = 1
