extends BattleScript

func _init() -> void:
	moveName = "Dodge"
	inputScheme = InputManager.InputStates.HEXES
	windup = 0.25
	moveRange = 2

func _transformVirtualPosition(manager: InputManager, p_in: HexVector) -> HexVector:
	return manager.controller.map.hex_list[data[-1]].hex_pos.copy()

func selection_logic(manager: InputManager):
	var origin = user.virtual_pos
	var path: Array[HexTile] = []

	var map = manager.controller.map
	var litTiles: Array = await map.getHexesInRange(origin, moveRange)
	while len(path) < 1:
		manager.queueCommand = 0
		manager.setInputState(inputScheme)
		#for item in map.getHexesInRange(user.hex_pos, user.unitData.speed - len(path)):
		
		manager.controller.highlightRange(litTiles)
		await manager.selected
		manager.controller.unHighlightRange()
		
		if manager.actionState == InputManager.ActionState.CANCEL:
			path = []
			break
		if manager.actionState == InputManager.ActionState.FINISH:
			break
		
		for tile in litTiles:
			if tile.id == manager.selectedHex.data.id:
				path.push_back(manager.selectedHex.data)
				break
		
		while manager.selectorState != manager.InputStates.PENDING:
			await manager.get_tree().process_frame

	var id_path = []
	for hextile in path:
		id_path.push_back(hextile.id)
	data = id_path
	
	manager.controller.removeHighlights()
	manager.controller.unHighlightRange()
	
func execute(controller: BattleController):
	var tile_path: Array[HexTile] = []
	for id in data:
		tile_path.push_back(controller.map.hex_list[id])
	print(Time.get_ticks_msec())
	await user.movePath(tile_path)
