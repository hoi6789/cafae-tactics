extends Sprite3D
class_name BattleUnit

@export var unitData: Resource

var player: int
var team: int

## sets location. idk
func setLocation(q, r):
	position = HexMath.axis_to_3D(q, r)
	pass
