extends Node

var win :=false
var score = 0 # player's score
var level = 0 #player's current level
var game_finished := false
var bricks_left := 0
var quiz := false
@onready var win_label: Panel = $CanvasLayer/Panel
@onready var score_label: Label = $CanvasLayer/ScoreLabel
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
	$CanvasLayer/ScoreLabel.text = DialogueManager.get_dialogue_text('menu','score')[0] + str(score)
	$CanvasLayer/LevelLabel.text = "Level: "+str(level)
	refresh_label()

func refresh_label():
	score_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	# 2. Aligns the text inside to the Right side
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# 3. (Optional) If you haven't set the position in the editor, 
	# this locks it to the Top Right corner so it has space to grow backwards.
	score_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
