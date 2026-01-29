class_name ScriptAtlas
extends Resource


@export var scriptList: Array[Script]
var id_dict: Dictionary[String, int] = {}
var initialized = false


func init():
	if initialized:
		return
	initialized = true
	var id = 0
	for s in scriptList:
		var move_name = (s.new() as BattleScript).moveName
		id_dict[move_name] = id
		id += 1

func get_id(script: BattleScript) -> int:
	return id_dict[script.moveName]

func get_move(id: int) -> BattleScript:
	return (scriptList[id].new() as BattleScript)
