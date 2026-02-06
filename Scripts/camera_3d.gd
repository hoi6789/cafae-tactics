extends Camera3D
var spd = 4
var base_spd = 4
var mouse3Down = false

var targetPosition: Vector3

func _ready() -> void:
	targetPosition = position

func _input(event: InputEvent) -> void:
	## looking around with mouse 3
	if event is InputEventMouseMotion and mouse3Down:
		#print(event.relative)
		rotation.y -= event.relative.x * 0.01
		rotation.x -= event.relative.y * 0.01
		if rotation_degrees.x < -80: rotation_degrees.x = -80
	pass

func _process(delta: float) -> void:
	spd = base_spd*clamp(sqrt(abs(targetPosition.y)), 1, INF)
	## controls camera movement
	mouse3Down = Input.is_action_pressed("mouse3Down")
	if Input.is_action_pressed("camera_panRight"):
		targetPosition.x += cos(rotation.y) * delta * spd
		targetPosition.z += -sin(rotation.y) * delta * spd
		pass
		
	if Input.is_action_pressed("camera_panLeft"):
		targetPosition.x += -cos(rotation.y) * delta * spd
		targetPosition.z += sin(rotation.y) * delta * spd
		pass
		
	if Input.is_action_pressed("camera_panUp"):
		targetPosition.x += -sin(rotation.y) * delta * spd
		targetPosition.z += -cos(rotation.y) * delta * spd
		pass
		
	if Input.is_action_pressed("camera_panDown"):
		targetPosition.x += sin(rotation.y) * delta * spd
		targetPosition.z += cos(rotation.y) * delta * spd
		pass
		
	if Input.is_action_just_pressed("mouseWheelUp"):
		#print("a")
		targetPosition -= basis.z
		if targetPosition.y < 0.5: targetPosition.y = 0.5
		pass
		
	if Input.is_action_just_pressed("mouseWheelDown"):
		#print("a")
		targetPosition += basis.z
		if targetPosition.y < 0.5: targetPosition.y = 0.5
		pass
	
	position = lerp(position, targetPosition, delta*8)
