extends Sprite3D
class_name Bullet

var speed: float = 3.5
var origin: BattleUnit
var target: BattleUnit
var batscript: BattleScript

var controller: BattleController


func initialize(_origin: BattleUnit, _target: BattleUnit, _script: BattleScript):
	origin = _origin
	target = _target
	batscript = _script
	position = origin.position

func _process(delta: float) -> void:
	position += position.direction_to(target.position) * speed * delta

func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.get_parent_node_3d() == target:
		controller.killProjectile(self)
		batscript.onHit(controller)
	pass # Replace with function body.
