extends Node

@export var player: AudioStreamPlayer

@export var music: Array[AudioStream]

@export var musicIndex: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	musicIndex = randi() % (music.size())
	player.stream = music[musicIndex]
	player.play()
	pass # Replace with function body.
