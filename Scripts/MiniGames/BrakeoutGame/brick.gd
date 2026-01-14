extends RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#brick is hit

func hit():
	#add to score
	GameManager.addPoints(1)
	$CPUParticles2D.emitting = true # turn off particles
	$Sprite2D.visible = false #disable sprite so we can't see it
	$CollisionShape2D.disabled = true #disable collision shape so it can't interact with ball
	
	GameManager.bricks_left -= 1
	
	#count bricks left
	if GameManager.bricks_left <= 0:
		var ball = get_tree().get_first_node_in_group("Ball")
		if ball:
			ball.is_active = false

		await get_tree().create_timer(1).timeout
		queue_free()
		GameManager.win_game()
	else:
		await get_tree().create_timer(1).timeout
		queue_free()


	
	
