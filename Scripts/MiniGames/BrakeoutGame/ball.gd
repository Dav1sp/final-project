extends CharacterBody2D

var speed = 200 # initial speed
var dir = Vector2.DOWN #which direction
var is_active = false
signal space_confirmado

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	speed = speed + (20 * GameManager.level) # set initial direction for the ball when scene loads

func _input(event):
	# Esta função serve APENAS para disparar o sinal
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		# Isto avisa o "await" lá em cima que pode continuar
		space_confirmado.emit()
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if!is_active:
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity = Vector2(direction * speed, -speed)
			is_active = true
	if is_active:
		#move the ball
		var collision = move_and_collide(velocity * delta)
		#if collision, bounce
		if collision:
			velocity = velocity.bounce(collision.get_normal()) # get the direction it should bounce
			
			#keep ball from stalling
			if(velocity.y > 0 and velocity.y < 100):
				velocity.y = -200 #for if ball is going side to side too much
			if(velocity.x == 0):
				velocity.x = -200 #for when ball is stuck up and down
			
			#trigger hit()
			if collision.get_collider().has_method("hit"):
				collision.get_collider().hit() #call hit() on the brick we just collided with

func _process(delta: float) -> void:
	if GameManager.game_finished:
		set_physics_process(false)
	pass


func gameOver():
	GameManager.score = 0 #reset score if you want
	GameManager.level = GameManager.level #reset level if you want
	GameManager.win_label.text = "You Lose, Good Luck Next Time!\nPress Space to Continue"
	GameManager.win_label.visible = true
	await space_confirmado
	GameManager.score_label.visible = false
	GameManager.win_label.visible = false
	get_parent().exit_game()


func _on_deatzone_body_exited(body: Node2D) -> void:
	if body.name == "Ball":
		gameOver()
