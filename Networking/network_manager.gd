extends Node

var APP_ID: int = 480
var PORT: int = 8080
var is_owned: bool = false
var steam_id: int = 0
var steam_user: String = "Guest"
var lobby_id: int = -1
var player_count = 0
var hosting = false
var connected = false

var game_started = false

var infopanel: RichTextLabel

var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()

signal got_lobby_list
var lobby_arr
# Called when the node enters the scene tree for the first time.
func _init() -> void:
	OS.set_environment("SteamAppId",str(APP_ID))
	OS.set_environment("SteamGameId",str(APP_ID))
	pass
	
var oldstr = ""
func _process(delta):
	Steam.run_callbacks()
	var cur = str(hosting)+":"+str(multiplayer.get_peers())
	if cur != oldstr:
		oldstr = cur
		print(multiplayer.get_unique_id())
		print(cur)

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
	
	#setup steam call backs
	Steam.lobby_created.connect(_lobby_created)
	Steam.lobby_joined.connect(_peer_joined)
	Steam.lobby_match_list.connect(_lobby_list)
		

func get_lobbies() -> Array:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_DEFAULT)
	Steam.requestLobbyList()
	await got_lobby_list
	return lobby_arr

func host():
	hosting = true
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 2)
	
func _lobby_created(connect: int, id):
	print("created lobby with id: ", id)
	if connect == Steam.RESULT_OK:
		lobby_id = id
		peer.host_with_lobby(id)
		multiplayer.multiplayer_peer = peer
		
		Steam.setLobbyJoinable(id, true)
		Steam.setLobbyData(id, "mode", "TEST")
		Steam.setLobbyData(id, "name", "TEST")
		
		connected = true
		#create the multiplayer peer object

func _lobby_list(lobbies: Array):
	lobby_arr = []
	for lobby in lobbies:
		if Steam.getLobbyOwner(lobby) != 0 and Steam.getLobbyOwner(lobby) != steam_id:
			lobby_arr.push_back(lobby)
	got_lobby_list.emit()
	
func join(id):
	if hosting:
		Steam.leaveLobby(lobby_id)
	hosting = false
	Steam.joinLobby(id)

func _peer_joined(lobby: int, permissions: int, locked: bool, response: int):
		if hosting:
			return
		print("joined lobby " + str(lobby), ", ", response, ", ", locked)
		lobby_id = lobby
		player_count = Steam.getNumLobbyMembers(lobby_id)
		print("new count: " + str(player_count))
		#create the multiplayer peer object
		peer.connect_to_lobby(lobby)
		multiplayer.multiplayer_peer = peer
		print("setting timer")
		while len(multiplayer.get_peers()) < 1:
			await get_tree().create_timer(0.1).timeout
		print("timer active!")
		reset_player_list.rpc(multiplayer.get_unique_id())
		
		connected = true

@rpc("any_peer", "call_remote")
func reset_player_list(sender):
	player_count = Steam.getNumLobbyMembers(lobby_id)
	print(player_count)
	print("rpc from " + str(sender) +": "+ str(multiplayer.get_unique_id()))
	if hosting:
		reset_player_list.rpc(multiplayer.get_unique_id())

func startGame():
	get_tree().change_scene_to_file("res://node_3d.tscn")
	pass
