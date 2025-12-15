extends CharacterBody3D

@export_category("Player Settings")

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5

var jump = true
var timer = 0.0
var input_enabled = true

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_pivot = $Camera
var cam_initial_rot
@onready var animation = $Sprit/mermaid/AnimationPlayer
@onready var main = $".."
@onready var iteract_label = $"../text_box"

var area = null


func _ready():
	cam_initial_rot = camera_pivot.rotation 
	floor_stop_on_slope = false
	wall_min_slide_angle = 0

func _process(delta: float) -> void:
	if not input_enabled:
		return
		
	if Input.is_action_just_pressed("interact") and area !=null:
		do_minigame()

func _physics_process(delta):
	
	if not input_enabled:
		return
	# Get input vector from defined actions
	var input_dir = Input.get_vector("ui_down","ui_up","ui_left","ui_right")
	
	
	# Convert to 3D direction (X/Z plane)
	var direction = Vector3(input_dir.x, 0, input_dir.y)
	
	if direction != Vector3.ZERO:
		velocity.x = direction.normalized().x * SPEED
		velocity.z = direction.normalized().z * SPEED
		rotation.y = atan2(velocity.x, velocity.z)   # face movement direction
		run_animation()
	else:
		velocity.x = 0
		velocity.z = 0
		run_animation()
	
	# Gravity (always pulling down when not on floor)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0  # reset vertical velocity when grounded
		
	move_and_slide()
	# Make camera follow position

	# Lock camera rotation (keeps whatever you set in editor)
	camera_pivot.global_rotation = cam_initial_rot
	

func run_animation():
	if velocity.x == 0 and velocity.z == 0:
		animation.play("Idle")
	else:
		animation.play("Walk", 0.0, 1.5)
	return

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
		
	match self.area.get_meta("type_minigame"):
		"slide_puzzle":
			input_enabled = false
			var path_to_load = self.area.get_meta("game").replace('"', '')
			var path_image = self.area.get_meta("path").replace('"', '')
			var game_scene = load(path_to_load).instantiate()
			get_tree().current_scene.add_child(game_scene)
			iteract_label.hide()
			await game_scene.tree_exited
			iteract_label.show()
			self.input_enabled = true
		_:
			print("nothing")
	
