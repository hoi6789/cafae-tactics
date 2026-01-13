extends Node

@export var joinID: TextEdit
@export var lobbyLabel: Label
@export var lobbyButton: PackedScene 
@export var lobbyContainer: Container
var lobbies: Array
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkManager.init_steam()
	host()
	update_lobbies()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	lobbyLabel.text = str(NetworkManager.lobby_id)
	if NetworkManager.lobby_id > -1 and NetworkManager.hosting and NetworkManager.game_started == false and NetworkManager.player_count == 2:
		start_game.rpc()

func host() -> void:
	NetworkManager.host()

func _on_join_pressed() -> void:
	NetworkManager.join(int(joinID.text))

func update_lobbies() -> void:
	lobbies = await NetworkManager.get_lobbies()
	for child in lobbyContainer.get_children():
		child.queue_free()
	
	for lobby in lobbies:
		var newButton: LobbyButton = lobbyButton.instantiate()
		lobbyContainer.add_child(newButton)
		print(newButton.lobby_id, lobby)
		newButton.lobby_id = lobby
		newButton.update()

func _on_reload_button_pressed() -> void:
	update_lobbies()
	
@rpc("any_peer","call_local")
func start_game():
	NetworkManager.startGame()
	
