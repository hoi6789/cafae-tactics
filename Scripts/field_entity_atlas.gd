class_name FieldEntityAtlas
extends Resource


@export var entityList: Array[PackedScene]
var id_dict: Dictionary[String, int] = {}
var initialized = false


func init():
	if initialized:
		return
	initialized = true
	var id = 0

func get_entity(id: int) -> FieldEntity:
	var _entity: FieldEntity = (entityList[id] as PackedScene).instantiate()
	_entity.atlasID = id
	return _entity

func get_entity_scene(id: int) -> PackedScene:
	return (entityList[id] as PackedScene)
