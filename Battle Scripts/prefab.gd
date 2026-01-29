class_name BattleScript

var moveName: String
var desc: String
var windup: int
var backswing: int
var inputScheme: int

var moveRange: int
var rangeType: int

var damage: int

var user: BattleUnit
var data: Array = []

func selection_logic(manager: InputManager):
	manager.setInputState(inputScheme)

func execute(controller: BattleController):
	pass
