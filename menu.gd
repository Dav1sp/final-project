extends Control

@onready var new_game: Button = $new_game
@onready var change_language: Button = $change_language
@onready var portuguese: Button = $languague_menu/portuguese
@onready var ingles: Button = $languague_menu/ingles
@onready var japones: Button = $languague_menu/japones
@onready var italiano: Button = $languague_menu/italiano
@onready var montenegrino: Button = $languague_menu/montenegrino
@onready var languague_menu: Control = $languague_menu


var world_scene = preload("res://Scenes/Levels/scene_1.tscn")

func _ready() -> void:
	new_game.text = DialogueManager.get_dialogue_text('menu','new_game')[0]
	change_language.text = DialogueManager.get_dialogue_text('menu','change_language')[0]
	portuguese.text = DialogueManager.get_dialogue_text('menu','portugues')[0]
	ingles.text = DialogueManager.get_dialogue_text('menu','ingles')[0]
	japones.text = DialogueManager.get_dialogue_text('menu','japones')[0]
	italiano.text = DialogueManager.get_dialogue_text('menu','italiano')[0]
	montenegrino.text = DialogueManager.get_dialogue_text('menu','montenegrino')[0]
	languague_menu.hide()
	pass
	
func _on_change_language_pressed() -> void:
	languague_menu.show()
	pass # Replace with function body.


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_packed(self.world_scene)
	pass # Replace with function body.


func _on_portuguese_pressed() -> void:
	GameData.lang = "PT"
	_ready()
	pass # Replace with function body.


func _on_ingles_pressed() -> void:
	GameData.lang = "EN"
	_ready()
	pass # Replace with function body.


func _on_japones_pressed() -> void:
	GameData.lang = "JP"
	_ready()
	pass # Replace with function body.


func _on_italiano_pressed() -> void:
	GameData.lang = "IT"
	_ready()
	pass # Replace with function body.


func _on_montenegrino_pressed() -> void:
	GameData.lang = "ME"
	_ready()
	pass # Replace with function body.
