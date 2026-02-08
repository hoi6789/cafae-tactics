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
	manager.inputRange = moveRange
	manager.setInputState(inputScheme)
	manager.setValidationState(inputValidation)
	manager.controller.highlightRange(await _getTilesInRange(manager.controller))
	await manager.selected
	data = [manager.selectedUnit.unitID]
	manager.controller.unHighlightRange()

func _getTilesInRange(controller: BattleController) -> Array[HexTile]:
	return await controller.map.getHexesWithShortestPathDistance(user.virtual_pos,moveRange)

func execute(controller: BattleController):
	pass

func onHit(controller: BattleController):
	pass

func _transformVirtualPosition(manager: InputManager, p_in: HexVector) -> HexVector:
	return p_in

func launchMeleeAttack(controller: BattleController, _bypass_range = false) -> bool:
	var target = controller.getUnit(data[0])
	if _bypass_range or target.inRange(user, moveRange):
		await user.dealDamage(damage, target)
	return true
