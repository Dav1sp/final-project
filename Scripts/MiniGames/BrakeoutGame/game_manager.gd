extends Node


var score = 0 # player's score
var level = 0 #player's current level
var game_finished := false
var bricks_left := 0
@onready var win_label: Panel = $CanvasLayer/Panel
@onready var score_label: TextEdit = $CanvasLayer/ScoreLabel
@onready var lose_audio: AudioStreamPlayer = $loseAudio
@onready var win_audio: AudioStreamPlayer = $winAudio

func _ready():
	$CanvasLayer/ScoreLabel.hide()


# add points to score (called from elsewhere)
func addPoints(points):
	score += points
	
func win_game():
	if game_finished:
		return
	game_finished = true

func show_score(show: bool): 
	$CanvasLayer/ScoreLabel.show()

func _process(delta: float) -> void:
	# update GUI with new score
	$CanvasLayer/ScoreLabel.text = "Score: " + str(score)
	$CanvasLayer/LevelLabel.text = "Level: "+str(level)
