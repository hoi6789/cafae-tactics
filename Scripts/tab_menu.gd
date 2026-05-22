extends VFlowContainer

@export var tabs: TabBar
@export var panels: Array[Control]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_tab_bar_tab_clicked(tab: int) -> void:
	for panel in panels:
		panel.visible = (panel == panels[tab])
