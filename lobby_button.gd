class_name LobbyButton
extends Button

var lobby_id: int = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func update() -> void:
	print(Steam.getLobbyOwner(lobby_id))
	text = Steam.getFriendPersonaName(Steam.getLobbyOwner(lobby_id))


func _on_pressed() -> void:
	NetworkManager.join(lobby_id)
