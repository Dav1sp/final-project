extends Node3D


@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	animation_player.play("swim_all")
	return
	
func _process(delta: float) -> void:
	return
