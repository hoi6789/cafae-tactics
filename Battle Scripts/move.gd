extends BattleScript

func _init() -> void:
	moveName = "Move"
	inputScheme = InputManager.InputStates.HEXES
	windup = 1

func _transformVirtualPosition(manager: InputManager, p_in: HexVector) -> HexVector:
	return manager.controller.map.hex_list[data[-1]].hex_pos.copy()

func selection_logic(manager: InputManager):
	var origin = user.virtual_pos
	
	var points = [origin]
	var path: Array[HexTile] = []
	var effectiveLen: float = 0
	
	var lastHex = origin
	var map = manager.controller.map
	var litTiles: Array = await map.getHexesWithShortestPathDistance(lastHex, user.unitData.speed - effectiveLen)
	while effectiveLen < user.unitData.speed:
		manager.queueCommand = 0
		manager.setInputState(inputScheme)
		#for item in map.getHexesInRange(user.hex_pos, user.unitData.speed - len(path)):
		
		manager.controller.highlightRange(litTiles)
		await manager.selected
		
		for item in litTiles:
			item.hex.unrangeHighlight()
		if manager.selectedHex != null:
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
			var last_tile = map.get_hex(origin)
			if len(path) > 0:
				last_tile = path[-1]
			for tile in new_path:
				if last_tile != null:
					var cost = HexagonMap.getIntermovementCost(last_tile, tile)
					print("cost: ", cost)
					if effectiveLen + cost <= user.unitData.speed:
						effectiveLen += cost
					else:
						break
				last_tile = tile
				path.push_back(tile)
			manager.controller.highlightPath(path)
		litTiles = await map.getHexesWithShortestPathDistance(lastHex, user.unitData.speed - effectiveLen)
		if len(litTiles) == 0:
			break
	var id_path = []
	for hextile in path:
		id_path.push_back(hextile.id)
	data = id_path
	
	while true:
		if manager.actionState == InputManager.ActionState.CANCEL:
			path = []
			break
		if manager.actionState == InputManager.ActionState.FINISH:
			break
		manager.setInputState(InputManager.InputStates.CONFIRMATION)
		manager.controller.highlightPath(path)
		await manager.selected
	
	manager.controller.removeHighlights()
	
func execute(controller: BattleController):
	var tile_path: Array[HexTile] = []
	for id in data:
		tile_path.push_back(controller.map.hex_list[id])
	print(Time.get_ticks_msec())
	await user.movePath(tile_path,user.unitData.moveSpeed)
