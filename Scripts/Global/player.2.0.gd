extends CharacterBody3D

@export_group("Camera")
@export_range(0.0,1.0) var mouse_sensitivity := 0.25

@export_group("Movement")
@export var move_speed := 4.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0


var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.UP
var _gravity := -30.0
var input_enabled = true
var area = null
var minigame = false

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera:Camera3D = %Camera3D
@onready var _skin:Node3D = %mermaid

func ready():
	pass

	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed('left_click') and !minigame:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed('ui_cancel'):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Input.is_action_just_pressed("interact") and area !=null and !minigame:
		do_minigame()

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and 
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity

		
func _physics_process(delta: float) -> void:
	if not input_enabled:
		return
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -PI/6.0, PI/3.0)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta

	_camera_input_direction = Vector2.ZERO
	
	var raw_input := Input.get_vector("move_left","move_right","move_up","move_down")
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	velocity.y = y_velocity + _gravity * delta
	move_and_slide()
	
	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction
	
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y,target_angle, rotation_speed * delta)
	
	var ground_speed := velocity.length()
	if ground_speed > 0.0:
		move()
	else:
		idle()
	
func idle():
	_skin.get_node("AnimationPlayer").play("Idle")

func move():
	_skin.get_node("AnimationPlayer").play("Walk", 0.0, 1.5)
	
func body_enter_the_area(area_aux):
	self.area = area_aux
	print("enter")
	pass
	
func body_leave_the_area():
	self.area = null
	print("leave")
	pass

func do_minigame():
	if self.area == null:
		return
	self.minigame = true	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	match self.area.get_meta("type_minigame"):
		"slide_puzzle":
			var owner_node := self.area.get_parent() as Node3D
			owner_node.iteract.hide()
			input_enabled = false
			var path_to_load = self.area.get_meta("game").replace('"', '')
			var path_image = self.area.get_meta("path").replace('"', '')
			var game_scene = load(path_to_load).instantiate()
			game_scene.player = self
			game_scene.image_path = path_image
			game_scene.npc = owner_node
			game_scene.GRID = self.area.get_meta("grid")
			get_tree().current_scene.add_child(game_scene)
			await game_scene.tree_exited
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			self.input_enabled = true
		_:
			print("nothing")
