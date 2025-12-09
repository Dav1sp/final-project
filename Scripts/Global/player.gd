extends CharacterBody3D

@export_category("Player Settings")

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var EXP = 0.2

var jump = true
var timer = 0.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_pivot = $Camera
var cam_initial_rot
@onready var animation = $Sprit/Ameijoa2/AnimationPlayer

func _ready():
	cam_initial_rot = camera_pivot.rotation 
	floor_stop_on_slope = false
	wall_min_slide_angle = 0
	
func _physics_process(delta):
	# Get input vector from defined actions
	var input_dir = Input.get_vector("ui_down","ui_up","ui_left","ui_right")
	
	
	# Convert to 3D direction (X/Z plane)
	var direction = Vector3(input_dir.x, 0, input_dir.y)
	
	if direction != Vector3.ZERO:
		velocity.x = direction.normalized().x * SPEED
		velocity.z = direction.normalized().z * SPEED
		rotation.y = atan2(velocity.x, velocity.z)   # face movement direction
		if not self.jump and timer == 0.0:
			run_animation()
	else:
		velocity.x = 0
		velocity.z = 0
		if not self.jump and timer == 0.0:
			run_animation()
	
	# Gravity (always pulling down when not on floor)
	if not is_on_floor():
		self.EXP += 0.1
		velocity.y -= gravity * delta * self.EXP
	else:
		if self.timer == 0.0:
			self.EXP = 0.0
			self.jump = false
			velocity.y = 0  # reset vertical velocity when grounded
		
	move_and_slide()
	# Make camera follow position
	camera_pivot.global_position = global_position

	# Lock camera rotation (keeps whatever you set in editor)
	camera_pivot.global_rotation = cam_initial_rot
	

func run_animation():
	animation.play("open")
	return
