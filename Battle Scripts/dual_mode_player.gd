extends Node

@export var calmPlayer: AudioStreamPlayer
@export var activePlayer: AudioStreamPlayer

@export var calmMusic: Array[AudioStream]
@export var activeMusic: Array[AudioStream]

@export var musicIndex: int = 0
@export var volume = -10

var _delta = 0
var t = 0
var t_rev = 0
var playerActive = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	musicIndex = randi() % (calmMusic.size())
	playDualSong(musicIndex)
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	playerActive = InputManager.instance.executingInputs
	_delta = delta
	var thresh = 0.8
	var scaler = 1
	var prog = sin(0.5*PI*t**scaler)
	var rev_prog = sin(0.5*PI*(t_rev**scaler))
	activePlayer.volume_db = lerp(-80, volume, prog)
	calmPlayer.volume_db = lerp(-80, volume, rev_prog)
	
	if playerActive:
		t = clamp(t+delta, 0, 1)
		if t > thresh:
			t_rev = clamp(t_rev-delta, 0, 1)
	else:
		t_rev = clamp(t_rev+delta, 0, 1)
		if t_rev > thresh:
			t = clamp(t-delta, 0, 1)
	pass
	

func playDualSong(index):
	calmPlayer.stream = calmMusic[index]
	activePlayer.stream = activeMusic[index]
	
	var diff = calmPlayer.stream.get_length() - activePlayer.stream.get_length()
	calmPlayer.play(max(0, diff))
	activePlayer.play(max(0, -diff))
