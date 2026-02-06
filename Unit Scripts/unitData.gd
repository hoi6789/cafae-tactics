extends Resource
class_name UnitStats

@export var name: String
@export var maxHealth: int
var health: int
@export var attack: int
@export var defense: int
@export var speed: int
@export var moveSpeed: int
@export var sprites: SpriteFrames
@export var moveset: Array[Script]


static func DamageFormula(dmg_incoming: int, defender_stats: UnitStats):
	var dmg = dmg_incoming - defender_stats.defense
	if dmg_incoming > 0 and dmg < 1:
		dmg = 1
	if dmg < 0:
		dmg = 0
	return dmg
