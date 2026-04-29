class_name TileIcon
extends Panel
@export var textLabel: RichTextLabel
var id = -1
var data: HexTile
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func initialize(_id: int = id):
	#get data
	id = _id
	data = MapCreator.singleton.data.get_data(id)
	#set params to match data
	textLabel.text = data.name


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			MapCreator.singleton.select_hex_type(id)
