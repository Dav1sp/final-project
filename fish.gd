extends Node3D

@export_group("animatino fish")

@export var animation_name: String
@export var appear: float

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var change = false

func _ready():
	animation_player.play(self.animation_name)
	self.hide()
	return
	
func _process(delta: float) -> void:

	if GameData.progress >= self.appear and self.change == false:
		self.show()
	return
