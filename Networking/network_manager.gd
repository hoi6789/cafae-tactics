extends Node

var APP_ID: int = 480
var PORT: int = 5000
var is_owned: bool = false
var steam_id: int = 0
var steam_user: String = "Guest"
var lobby_id: int = 0

var infopanel: RichTextLabel

var peer: SteamMultiplayerPeer
# Called when the node enters the scene tree for the first time.
func _init() -> void:
	OS.set_environment("SteamAppId",str(APP_ID))
	OS.set_environment("SteamGameId",str(APP_ID))
	pass
	
func _process(delta):
	Steam.run_callbacks()
	
func init_steam():
	#ask steam for permission to connect
	var init_resp: Dictionary = Steam.steamInitEx()
	print("init: ", init_resp)
	
	#if steam is not open then close the game
	if init_resp['status'] > 0:
		print("failed to initialize steam")
		get_tree().quit()
	
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_user = Steam.getPersonaName()
	
	#if we dont own the game, close it (pirate removal strategies)
	if is_owned == false:
		get_tree().quit()
	
	#add our info to the info panel
	infopanel.text += "\n"+steam_user + ": " + str(steam_id)
	
	#setup steam call backs
	Steam.lobby_created.connect(_lobby_created)
	Steam.lobby_match_list.connect(_lobby_list)
	
	#create the multiplayer peer object
	peer = SteamMultiplayerPeer.new()
	
	
	
	
func _joined(connect: int, id):
	if connect == 1:
		infopanel.text += "\nLobby ID: " + str(id)

func get_lobbies():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_DEFAULT)
	Steam.requestLobbyList()

func _lobby_created(connect: int, id):
	print("created lobby with id: ", id)
	if connect == 1:
		lobby_id = id
		Steam.setLobbyJoinable(id, true)
		Steam.setLobbyData(id, "mode", "TEST")
		Steam.setLobbyData(id, "name", "TEST")
		peer.host_with_lobby(id)
		infopanel.text += "\nLobby ID: " + str(id)

func _lobby_list():
	pass
	
func join(id):
	peer.create_client(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_joined)
	peer.connect_to_lobby(id)

func host():
	peer.create_host(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_joined)
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 2)
