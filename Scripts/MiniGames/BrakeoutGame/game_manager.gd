extends Node


var score = 0 # player's score
var level = 3 #player's current level
var game_finished := false
var bricks_left := 0

func _ready():
	$CanvasLayer/ScoreLabel.visible = false


# add points to score (called from elsewhere)
func addPoints(points):
	score += points
func win_game():
	if game_finished:
		return
	game_finished = true
	if has_node("CanvasLayer/WinLabel"):
		$CanvasLayer/WinLabel.visible = true
		$CanvasLayer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

func show_score(show: bool): 
	$CanvasLayer/ScoreLabel.visible = show

func _process(delta: float) -> void:
	# update GUI with new score
	$CanvasLayer/ScoreLabel.text = str(score)
	$CanvasLayer/LevelLabel.text = "Level: "+str(level)
