extends Sprite3D
class_name Bullet

var speed: float = 1
var origin: BattleUnit
var target: BattleUnit
var batscript: BattleScript

func initialize(_origin: BattleUnit, _target: BattleUnit, _script: BattleScript):
	origin = _origin
	target = _target
	position = origin.position

func _process(delta: float) -> void:
	position += position.direction_to(target.position) * speed * delta
