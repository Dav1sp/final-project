extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var animation_name: String = "open"
@export var min_time := 3.0
@export var max_time := 6.0
@export var iteract:CanvasLayer
@onready var iteract_range = $"iteract range"

var player_in_zone := false

func _on_area_3d_body_entered(body):
	if body is CharacterBody3D:  # detect the player
		player_in_zone = true
		print("Player entered the zone!")

func _on_area_3d_body_exited(body):
	if body is CharacterBody3D:
		player_in_zone = false
		print("Player left the zone!")
		
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
	if body is CharacterBody3D:
		body.body_enter_the_area(iteract_range)
		iteract.get_node("TextEdit").text = DialogueManager.get_dialogue_text('menu','press_e_npc')[0]
		iteract.show()



func _on_iteract_range_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.body_leave_the_area()
		iteract.hide()
