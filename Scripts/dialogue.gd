extends CanvasLayer

signal player_pressed_space
signal player_pressed_enter
const CHAR_READ_RATE = 0.05

@onready var textbox_container = $TextboxContainer
@onready var name_symbol = $TextboxContainer/MarginContainer/HBoxContainer/Name
@onready var text_layer = $TextboxContainer/MarginContainer/HBoxContainer/text
@onready var press_spacebar = $"TextboxContainer/MarginContainer/HBoxContainer/Press Spacebar"
@onready var input = $disable_input
@onready var input_val = $disable_input/insertInput

var player_data = {}
var current_language = "ME"

var is_waiting_for_space = false
var is_waiting_for_input = false

const DIALOGUE_FILE = preload("res://Data/dialogue.json")


func _ready():
	hide_textbox()
	var dialogue_data = DIALOGUE_FILE.data
	start_dialogue(dialogue_data['scene_intro']['Nacar'],current_language)
	print(dialogue_data['scene_intro']['Nacar'])


func hide_textbox():
	press_spacebar.text = ''
	text_layer.text = ''
	name_symbol.text = ''
	textbox_container.hide()
	input.hide()
	text_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var v_bar = text_layer.get_v_scroll_bar()
	
	# Tira o fundo da barra
	v_bar.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	v_bar.add_theme_stylebox_override("scroll_focus", StyleBoxEmpty.new())
	v_bar.add_theme_stylebox_override("grabber", StyleBoxEmpty.new())
	v_bar.add_theme_stylebox_override("grabber_highlight", StyleBoxEmpty.new())
	v_bar.add_theme_stylebox_override("grabber_pressed", StyleBoxEmpty.new())
	
	# Truque extra: Força a largura dela a ser 0 para não ocupar espaço
	v_bar.custom_minimum_size.x = 0
	return

func show_textbox():
	press_spacebar.text = 'press spacebar'
	textbox_container.show()

func _unhandled_input(event):
	# If we press Space, we shout "I pressed space!"
	if event.is_action_pressed("ui_accept"):
		player_pressed_space.emit()
		
func add_text(next_text,person):
	name_symbol.text = person+':'
	text_layer.text = next_text
	text_layer.visible_characters = 0 	
	show_textbox()


func start_dialogue(dialogue_array: Array,language):
	show_textbox()
	
	# Loop through every line in the array one by one
	for line_data in dialogue_array:
		
		# A. PREPARE THE TEXT
		var text_to_show = line_data.get(language, "...")
		
		# Check if we need to swap %s for a variable (like "Hugo")
		if line_data.has("receive_input") and line_data["receive_input"]:
			var var_name = line_data["receive_input_order"][0]
			text_to_show = text_to_show % player_data.get(var_name, "Unknown")
		
		# B. SHOW ANIMATION
		await animate_text(text_to_show,'Nacar') # Code pauses here until text finishes typing
		
		# C. CHECK: DO WE NEED INPUT OR JUST SPACEBAR?
		if line_data.has("input") and line_data["input"]:
			await player_pressed_space
			input.show()
			var result = await input_val.text_submitted
			
			player_data[line_data["input_name"]] = result
			input.hide()
			input_val.clear()
			
		else:
			await player_pressed_space	
	# Loop finished? Hide everything.
	hide_textbox()
	
func animate_text(text,character):
	name_symbol.text = character+':'
	text_layer.text = text
	text_layer.visible_characters = 0
	
	var duration = text.length() * CHAR_READ_RATE
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(text_layer, "visible_characters", text.length(), duration)
	
	# Pause the function until the tween is done
	await tween.finished
