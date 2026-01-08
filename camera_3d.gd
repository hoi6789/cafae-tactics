extends Camera3D
var spd = 1
var mouse3Down = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse3Down:
		print(event.relative)
		rotation.y -= event.relative.x * 0.01
		rotation.x -= event.relative.y * 0.01
		if rotation_degrees.x < -80: rotation_degrees.x = -80
	pass

func _process(delta: float) -> void:
	mouse3Down = Input.is_action_pressed("mouse3Down")
	if Input.is_action_pressed("camera_panRight"):
		position.x += cos(rotation.y) * delta * spd
		position.z += -sin(rotation.y) * delta * spd
		pass
		
	if Input.is_action_pressed("camera_panLeft"):
		position.x += -cos(rotation.y) * delta * spd
		position.z += sin(rotation.y) * delta * spd
		pass
		
	if Input.is_action_pressed("camera_panUp"):
		position.x += -sin(rotation.y) * delta * spd
		position.z += -cos(rotation.y) * delta * spd
		pass
		
	if Input.is_action_pressed("camera_panDown"):
		position.x += sin(rotation.y) * delta * spd
		position.z += cos(rotation.y) * delta * spd
		pass
		
	if Input.is_action_just_pressed("mouseWheelUp"):
		print("a")
		position -= basis.z
		if position.y < 0.5: position.y = 0.5
		pass
		
	if Input.is_action_just_pressed("mouseWheelDown"):
		print("a")
		position += basis.z
		if position.y < 0.5: position.y = 0.5
		pass
