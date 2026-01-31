extends BattleScript

func _init() -> void:
	moveName = "Move"
	inputScheme = InputManager.InputStates.HEXES
	windup = 1
	

func selection_logic(manager: InputManager):
	var points = [user.hex_pos]
	var path: Array[HexTile] = []
	while len(path) < user.unitData.speed:
		manager.queueCommand = 0
		manager.setInputState(inputScheme)
		
		await manager.selected
		
		if manager.actionState == InputManager.ActionState.CANCEL:
			path = []
			break
		if manager.actionState == InputManager.ActionState.FINISH:
			break
		
		points.push_back(manager.selectedHex.data.hex_pos)
		var map = manager.controller.map
		var new_path = map.getShortestPath(map.get_hex(points[-2]),map.get_hex(points[-1]))
		if len(new_path) > 0:
			new_path.remove_at(0)
			path += new_path
			if len(path) > user.unitData.speed:
				path = path.slice(0,user.unitData.speed)
			manager.controller.highlightPath(path)
	var id_path = []
	for hextile in path:
		id_path.push_back(hextile.id)
	data = id_path
	manager.controller.removeHighlights()
	
func execute(controller: BattleController):
	var tile_path: Array[HexTile] = []
	for id in data:
		tile_path.push_back(controller.map.hex_list[id])
	print(Time.get_ticks_msec())
	await user.movePath(tile_path)
