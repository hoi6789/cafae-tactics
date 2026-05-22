class_name EditorIcon
extends Panel

var id = -1
static var icons: Array[EditorIcon] = []
var icon_mode: MapCreator.PlacementData.SelectionMode
@export var textLabel: RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EditorIcon.icons.push_back(self)

func isSelected() -> bool:
	return false

static func totalUpdate():
	for icon in icons:
		icon.updateColour() 

func updateColour():
	if isSelected():
		textLabel.self_modulate = Color.GOLDENROD
	else:
		textLabel.self_modulate = Color.WHITE
