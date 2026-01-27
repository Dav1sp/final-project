extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var animation_name: String = "Idle"

@export var iteract:CanvasLayer
@export var iteract_range:Area3D

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
	animation_player.play(animation_name)

func _on_iteract_range_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.body_enter_the_area(iteract_range)
		iteract.get_node("TextEdit").text = DialogueManager.get_dialogue_text('menu','press_e_npc')[0]
		iteract.show()



func _on_iteract_range_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.body_leave_the_area()
		iteract.hide()
