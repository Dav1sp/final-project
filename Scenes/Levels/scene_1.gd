extends Node3D
@onready var light_dark = $DirectionalLight3D
@onready var light_sun = $DirectionalLight3D2
func _ready():
	return

func _on_iteract_range_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		print('enter')
		light_dark.hide()
		light_sun.show()
	

func _on_iteract_range_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		print('leave')
		light_dark.show()
		light_sun.hide()
