class_name BattleScript

var moveName: String
var desc: String
var windup: float
var backswing: float
var inputScheme: int
var inputValidation: int

var moveRange: int
var rangeType: int

var damage: int

var user: BattleUnit
var data: Array = []

func selection_logic(manager: InputManager):
	manager.setInputState(inputScheme)

func execute(controller: BattleController):
	pass
	
func launchMeleeAttack(controller: BattleController) -> bool:
	user.dealDamage(damage, controller.getUnit(data[0]))
	return true
