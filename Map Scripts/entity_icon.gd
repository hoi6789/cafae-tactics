class_name EntityIcon
extends EditorIcon


var entity_prefab_data: PackedScene

	
func isSelected() -> bool:
	return (icon_mode == MapCreator.singleton.placementData.selectionMode) and (MapCreator.singleton.placementData.current_entity_id == id)

func initialize(_id: int = id):
	icon_mode = MapCreator.PlacementData.SelectionMode.ENTITY
	#get data
	id = _id
	entity_prefab_data = MapCreator.singleton.entityData.get_entity_scene(id)
	#set params to match data
	var test_entity = MapCreator.singleton.entityData.get_entity(id)
	var entity_name = test_entity.name
	test_entity.queue_free()
	textLabel.text = entity_name


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			MapCreator.singleton.select_entity_type(id)
			totalUpdate()
