extends Node

@export var joinID: TextEdit
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func host() -> void:
	NetworkManager.infopanel = $Info/InfoText
	NetworkManager.init_steam()
	
	
	$Host.disabled = false
	$Join.disabled = false


func _on_host_button_pressed() -> void:
	host() # Replace with function body.


func _on_host_pressed() -> void:
	NetworkManager.host() # Replace with function body.


func _on_join_pressed() -> void:
	NetworkManager.join(int(joinID.text))
