extends AnimatedSprite3D
class_name BattleHologram
## BattleHologram is intentionally different from BattleUnit. This increases duplication but
## decreases possible bugs relating to detecting/treating holograms as if they were real units.
## [br]
## BattleHolograms are client-side only and are always owned by a BattleUnit.
## BattleUnits clear out any existing holograms when a turn is ended.
## [br]
## BattleHolograms should always access their parent unit's when clicked. They should be
## valid targets for attacks, in warning colours.
## When we feed a unit's position to a script for rangefinding and whatnot we should feed the hologram's 
## position instead if it was the source.

var yours: bool = true
var sprites: SpriteFrames
var inputManager: InputManager
var hex_pos: HexVector
@export var unit: BattleUnit

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	unit._on_input_event(camera, event, event_position, normal, shape_idx)


func _on_mouse_entered() -> void:
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	pass # Replace with function body.




func _process(delta: float) -> void:
	#filler script until angela finishes the real thing
	if unit != null and unit.hex_pos != null and unit.virtual_pos != null and unit.inputManager.executingInputs == false:
		sprite_frames = unit.sprite_frames
		animation = unit.animation
		frame = unit.frame
		flip_h = unit.flip_h
		flip_v = unit.flip_v
		hex_pos = unit.virtual_pos
		visible = !HexVector._equals(unit.hex_pos, unit.virtual_pos)
		global_position = unit.get_parent().global_position + HexMath.axis_to_3D(hex_pos.q, hex_pos.r) 
		global_position.y = unit.get_parent().global_position.y + unit.position.y
	else:
		visible = false
	
