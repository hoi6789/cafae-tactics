extends AnimatedSprite3D
class_name FieldEntity
var hex_pos: HexVector
var hex_height: float
var virtual_pos: HexVector
var inputManager: InputManager
var playerID: int
var unitID: int
var teamID: int

var _calculating_sight = false
var sightRange = 0
var sight: Array[HexTile]

var target_pos: HexVector
var _delta = 0
var last_position: Vector3 

var spriteHeight: float = 1

func isOwned():
	return (NetworkManager.steam_id == playerID)
	
func setAnimation(anim: String):
	animation = anim
	pass

## sets location. idk
func setLocation(hex_vec: HexVector, _height: int):
	hex_pos = hex_vec
	hex_height = _height
	setAnimation("default")
	updateSight()
	pass

func movePath(path: Array[HexTile], speed: float):
	var lastTile = inputManager.controller.map.get_hex(hex_pos)
	for data in path:
		var cost: float = 1
		if lastTile != null:
			cost = inputManager.controller.map.getIntermovementCost(lastTile, data)
		lastTile = data
		await move(data, speed, 1.0/cost)
	setAnimation("default")

func jump_parabola(h0:float,h1:float,v:float, t:float):
	var b = 4*(v-h0)+h0-h1
	var c = h0
	var a = h1-h0-b
	t = clampf(t, 0, 1)
	return a*t**2+b*t+c

func move(tile: HexTile, move_speed: float, speed_scaler: float):
	print("moving")
	setAnimation("moving")
	
	target_pos = tile.hex_pos
	var t = 0
	var original_height = hex_height
	var original_pos = hex_pos
	var parabola_scale = 0
	
	if original_height != tile.height:
		speed_scaler = 1.0/float(HexTile.JUMP_COST)
	
	while t < 1:
		hex_pos = HexVector.lerp(original_pos, tile.hex_pos, t)
		if original_height != tile.height:
			hex_height = jump_parabola(original_height, tile.height, tile.height+2, t)
		t += _delta*move_speed*speed_scaler
		await get_tree().create_timer(_delta).timeout
	
	updateSight()
	hex_pos = target_pos
	hex_height = tile.height


func updateSight(pos = hex_pos):
	if sightRange == 0:
		return
	if _calculating_sight:
		return
	_calculating_sight = true
	sight = await inputManager.controller.map.getSight(pos,10)
	_calculating_sight = false
	inputManager.controller.updateTeamSight(teamID)

func getPosition(_hvec: HexVector, _height: float):
	var newSH =  sprite_frames.get_frame_texture(animation, frame).get_height()*pixel_size
	if newSH != spriteHeight:
		spriteHeight = newSH
		print("nSH: ", newSH)
	
	var hpos: Vector3 = HexMath.axis_to_3D(_hvec.q, _hvec.r)
	hpos.y = 0
	return hpos + Vector3(0,(_height)*Hex.TILE_HEIGHT + spriteHeight/2,0)

func getCurrentHexTile() -> HexTile:
	if inputManager == null:
		return null
	return inputManager.controller.map.get_hex(hex_pos)

func canSee() -> bool:
	var hex: HexTile = getCurrentHexTile()
	return (hex != null) and hex.hex.can_see

func update(delta: float):
	_delta = delta
	if hex_pos != null:
		position = getPosition(hex_pos, hex_height)
	
	if last_position != position:
		var tranform_matrix = get_viewport().get_camera_3d().global_transform.affine_inverse()
		var cube_start = tranform_matrix * last_position
		var cube_end = tranform_matrix * position
		var screen_vel = cube_end - cube_start
		if screen_vel.x != 0:
			flip_h = (screen_vel.x > 0)
	
	visible = canSee()
	
	last_position = position	
