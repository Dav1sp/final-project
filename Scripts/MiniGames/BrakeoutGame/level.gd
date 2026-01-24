extends Node2D

#block scene used to instantiate
@onready var brickObject = preload("res://Scenes/MiniGames/BrakeoutGame/brick.tscn")
@onready var setting_background: ColorRect = $setting_background
@onready var mute: Button = $Panel/Panel/Mute
@onready var volume: Button = $Panel/Panel/Volume

@export var player: CharacterBody3D
@export var npc: Node3D
var columns = 32 # number of columns of blocks
var rows = 7 # number of rows of blocks
var margin = 50 # distance from edge of screen
signal space_confirmado

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.show_score(true)
	setupLevel()

func _input(event):
	# Esta função serve APENAS para disparar o sinal
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		# Isto avisa o "await" lá em cima que pode continuar
		space_confirmado.emit()

func setupLevel():
	#set row count based on level
	rows = 3 + GameManager.level
	#put a cap on a max number of rows
	if(rows > 9):
		rows = 9
		
	GameManager.bricks_left = 0
	GameManager.game_finished = false
	get_tree().paused = false
	
	#get colors for blocks
	var colors = getColors()
	colors.shuffle()
	
	#place blocks on screen
	for r in range(rows):
		for c in range(columns):
			#generate random number
			var randomNumber = randi_range(0,2)
			if randomNumber > 0:

				var newBrick = brickObject.instantiate()
				add_child(newBrick)
				newBrick.get_node("Sprite2D").scale = Vector2(0.5,0.5)
				newBrick.position = Vector2(margin + (34 * c), margin + (34 * r))
				GameManager.bricks_left += 1
				
				#give block sprite some color
				var sprite = newBrick.get_node('Sprite2D')
				if r >= 6:
					sprite.modulate =  colors[0]
				if r < 6:
					sprite.modulate =  colors[1]
				if r < 4:
					sprite.modulate =  colors[2]
				if r < 2:
					sprite.modulate =  colors[3]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if GameManager.game_finished:
		GameManager.win_label.text = 'Congratulation, you completed the game!\n Press space to continue'
		GameManager.win_label.visible = true
		await space_confirmado
		GameManager.score = 0
		GameManager.win_label.visible = false
		exit_game()
	pass
func getColors():
	var colors = [
		Color(0.625, 1.137, 1.164, 1.0),
		Color("ffb9f5ff"),
		Color(0.733, 0.978, 0.493, 1.0),
		Color(1.11, 1.11, 1.11, 1.0)
	]
	
	return colors
	
	
func _on_volume_pressed() -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	
	var is_muted = AudioServer.is_bus_mute(master_bus)

	AudioServer.set_bus_mute(master_bus, not is_muted)
	self.mute.show()
	self.volume.hide()
	pass

func _on_mute_pressed() -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	# Set mute to FALSE to hear sound again
	AudioServer.set_bus_mute(master_bus, false)
	self.mute.hide()
	self.volume.show()
	pass # Replace with function body.
	
func _on_settings_pressed() -> void:
	self.setting_background.show()
	get_tree().paused = true
	pass # Replace with function body.
	
func _on_close_pressed() -> void:
	self.setting_background.hide()
	get_tree().paused = false
	pass # Replace with function body.

func exit_game():
	get_tree().paused = false
	self.player.minigame = false
	GameManager.score_label.visible = false
	GameManager.win_label.visible = false
	self.npc.iteract.show()
	queue_free()
	pass
	
func _on_exit_game_pressed() -> void:
	exit_game()



func _on_save_game_pressed() -> void:
	pass # Replace with function body.
