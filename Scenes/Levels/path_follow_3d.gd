extends PathFollow3D

@export var velocity: float


func _process(delta: float) -> void:
	progress += velocity*delta
