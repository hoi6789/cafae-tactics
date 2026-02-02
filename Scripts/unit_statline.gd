class_name UnitStatLine

var maxHP = 0
var hp = 0
# Called when the node enters the scene tree for the first time.
func _init(data: UnitStats) -> void:
	maxHP = data.maxHealth
	hp = maxHP
