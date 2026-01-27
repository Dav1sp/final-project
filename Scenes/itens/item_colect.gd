extends Node3D

@export var name_item:String
@export var iteract:CanvasLayer = null
@export var iteract_range:Area3D = null
@export var pearl:bool=false

func _on_iteract_range_body_entered(body: Node3D) -> void:
	if self.pearl and !GameData.itens:
		if body is CharacterBody3D and iteract_range!=null and GameData.pearl:
			body.body_enter_the_area(iteract_range)
			iteract.get_node("TextEdit").text = DialogueManager.get_dialogue_text('menu','press_e_object')[0] % DialogueManager.get_dialogue_text('menu',iteract_range.get_meta("name"))[0]
			iteract.show()
	elif self.pearl and GameData.itens:
		if self.pearl and GameData.pearl:
			if body is CharacterBody3D and iteract_range!=null:
				body.body_enter_the_area(iteract_range)
				iteract.get_node("TextEdit").text = DialogueManager.get_dialogue_text('menu','press_e_object')[0] % DialogueManager.get_dialogue_text('menu',iteract_range.get_meta("name"))[0]
				iteract.show()
		else:
			if body is CharacterBody3D and iteract_range!=null and !self.pearl:
				body.body_enter_the_area(iteract_range)
				iteract.get_node("TextEdit").text = DialogueManager.get_dialogue_text('menu','press_e_object')[0] % DialogueManager.get_dialogue_text('menu',iteract_range.get_meta("name"))[0]
				iteract.show()
	elif !self.pearl and GameData.itens:
		if body is CharacterBody3D and iteract_range!=null and GameData.itens:
			body.body_enter_the_area(iteract_range)
			iteract.get_node("TextEdit").text = DialogueManager.get_dialogue_text('menu','press_e_object')[0] % DialogueManager.get_dialogue_text('menu',iteract_range.get_meta("name"))[0]
			iteract.show()
	pass # Replace with function body.


func _on_iteract_range_body_exited(body: Node3D) -> void:
	if pearl and !GameData.itens:
		if body is CharacterBody3D and iteract_range!=null and GameData.pearl:
			body.body_leave_the_area()
			iteract.hide()
	elif pearl and GameData.itens:
		if self.pearl and GameData.pearl:
			if body is CharacterBody3D and iteract_range!=null:
				body.body_leave_the_area()
				iteract.hide()
		else:	
			if body is CharacterBody3D and iteract_range!=null and !self.pearl:
				body.body_leave_the_area()
				iteract.hide()
	elif !pearl and GameData.itens and iteract_range!=null and GameData.itens:
		if body is CharacterBody3D:
			body.body_leave_the_area()
			iteract.hide()
	pass # Replace with function body.
