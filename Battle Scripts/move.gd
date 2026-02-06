extends BattleScript

func _init() -> void:
	moveName = "Move"
	inputScheme = InputManager.InputStates.HEXES
	windup = 1
	

func selection_logic(manager: InputManager):
	var points = [user.hex_pos]
	var path: Array[HexTile] = []
	var effectiveLen: int = 0
	var lastHex = user.hex_pos
	while effectiveLen < user.unitData.speed:
		manager.queueCommand = 0
		manager.setInputState(inputScheme)
		var map = manager.controller.map
		var litTiles = await map.getFloodedRange(map.get_hex(lastHex), user.unitData.speed - effectiveLen)
		#for item in map.getHexesInRange(user.hex_pos, user.unitData.speed - len(path)):
		
		for item in litTiles:
			item.hex.rangeHighlight()
		await manager.selected
		
		for item in litTiles:
			item.hex.unrangeHighlight()
		lastHex = manager.selectedHex.data.hex_pos
		
		if manager.actionState == InputManager.ActionState.CANCEL:
			path = []
			break
		if manager.actionState == InputManager.ActionState.FINISH:
			break
		
		points.push_back(manager.selectedHex.data.hex_pos)
		var new_path: Array[HexTile] = await map.getShortestPath(map.get_hex(points[-2]),map.get_hex(points[-1]))
		if len(new_path) > 0:
			new_path.remove_at(0)
			for tile in new_path:
				effectiveLen += tile.getMovementCost()
				if effectiveLen > user.unitData.speed:
					break
				path.push_back(tile)
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
