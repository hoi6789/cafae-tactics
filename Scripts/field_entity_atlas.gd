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

func get_id(script: BattleScript) -> int:
	return id_dict[script.moveName]

func get_entity(id: int) -> FieldEntity:
	return (entityList[id] as PackedScene).instantiate()
