extends Node3D

@export var name_item:String

@onready var iteract = $"../../text_box"
@onready var iteract_range = $"iteract range"

func _on_iteract_range_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.body_enter_the_area(iteract_range)
		iteract.get_node("TextEdit").text = 'Press E to collect '+self.name_item
		iteract.show()
	pass # Replace with function body.


func _on_iteract_range_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.body_leave_the_area()
		iteract.hide()
	pass # Replace with function body.
