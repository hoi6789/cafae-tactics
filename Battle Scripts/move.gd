extends BattleScript

func _init() -> void:
	moveName = "Move"
	inputScheme = InputManager.InputStates.HEXES
	

func selection_logic(manager: InputManager):
	var points = [user.hex_pos]
	var path: Array[HexTile] = []
	while len(path) < user.unitData.speed:
		manager.queueCommand = 0
		manager.setInputState(inputScheme)
		await manager.selected
		points.push_back(manager.selectedHex.data.hex_pos)
		var map = manager.controller.map
		var new_path = map.getShortestPath(map.get_hex(points[-2]),map.get_hex(points[-1]))
		if len(new_path) > 0:
			new_path.remove_at(0)
			path += new_path
			if len(path) > user.unitData.speed:
				path = path.slice(0,user.unitData.speed)
			manager.controller.highlightPath(path)
