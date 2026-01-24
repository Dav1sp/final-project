extends Node3D

@export var animation_name: String = "open"
@export var min_time := 3.0
@export var max_time := 6.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	randomize()
	_schedule_next()

func _schedule_next():
	var wait_time = randf_range(min_time, max_time)
	await get_tree().create_timer(wait_time).timeout
	_play_animation()

func _play_animation():

	animation_player.play("open")

	var length = animation_player.get_animation(animation_name).length
	await get_tree().create_timer(length).timeout
	_schedule_next()


func _on_iteract_range_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
