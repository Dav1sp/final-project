extends Node2D

#block scene used to instantiate
@onready var brickObject = preload("res://Scenes/MiniGames/BrakeoutGame/brick.tscn")

var columns = 32 # number of columns of blocks
var rows = 7 # number of rows of blocks
var margin = 50 # distance from edge of screen

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.show_score(true)
	setupLevel()

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
	pass
func getColors():
	var colors = [
		Color( 0, 1, 1, 1 ),
		Color( 0.54, 0.17, 0.89, 1 ),
		Color( 0.68, 1, 0.18, 1 ),
		Color( 1,1,1, 1 )
	]
	
	return colors
