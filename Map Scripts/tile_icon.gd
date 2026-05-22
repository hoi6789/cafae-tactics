class_name TileIcon
extends EditorIcon



var data: HexTile


func isSelected() -> bool:
	return (icon_mode == MapCreator.singleton.placementData.selectionMode) and (MapCreator.singleton.placementData.current_hex_id == id)

func initialize(_id: int = id):
	icon_mode = MapCreator.PlacementData.SelectionMode.HEX
	#get data
	id = _id
	data = MapCreator.singleton.data.get_data(id)
	#set params to match data
	textLabel.text = data.name


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			MapCreator.singleton.select_hex_type(id)
			totalUpdate()
