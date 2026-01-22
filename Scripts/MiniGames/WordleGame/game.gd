extends Node2D

@onready var grid: GridContainer = $GridContainer
@onready var menu: CanvasLayer = $Menu

@onready var label: Label = $Menu/ResultLabel
@onready var word_label: Label = $Menu/WordLabel
@onready var cursor: ColorRect = $Cursor
@onready var cursor_timer: Timer = $CursorTimer

# Podesavanja igre
const MAX_LEN := 10       # 🔹 1–5 slova po pokušaju
const ATTEMPTS := 5      # broj pokušaja
const MIN_LEN := 1
var cursor_slot_valid := false
const CURSOR_HEIGHT := 70


# Dugmad u gridu (tipizirano)
var buttons: Array[Button] = []

# Game state
var wordle: String = ""
var index := 0
var current_row := 0

func _on_cursor_timer():
	if not cursor_slot_valid:
		cursor.visible = false
		return

	cursor.visible = !cursor.visible



func _ready():
	buttons.clear()
	cursor_timer.timeout.connect(_on_cursor_timer)
	cursor.visible = true
	for n in grid.get_children():
		var b := n as Button
		if b != null:
			buttons.append(b)

	reset_game()

func update_cursor():
	var row_start := current_row * MAX_LEN
	var row_end := row_start + MAX_LEN

	# validno mjesto samo ako je index u aktivnom redu i NIJE na kraju reda
	cursor_slot_valid = (index >= row_start and index < row_end and index < buttons.size())

	if not cursor_slot_valid:
		cursor.visible = false
		return

	var btn := buttons[index]
	var rect := btn.get_global_rect()

	cursor.global_position = Vector2(
		rect.position.x + rect.size.x / 2 - cursor.size.x / 2,
		rect.position.y
	)

	#cursor.size.y = rect.size.y
	cursor.global_position = Vector2(
	rect.position.x + rect.size.x / 2 - cursor.size.x / 2,
	rect.position.y + (rect.size.y - CURSOR_HEIGHT) / 2
	)
	cursor.size.y = CURSOR_HEIGHT
	cursor.visible = true



func clear_cursor():
	cursor.visible = false
	cursor_timer.stop()


func _input(event):
	if menu.visible:
		return

	# Unos slova A–Z
	if event is InputEventKey and event.is_pressed() and not event.echo:
		if event.keycode >= KEY_A and event.keycode <= KEY_Z:
			var row_end := (current_row + 1) * MAX_LEN
			if index < row_end and index < buttons.size():
				buttons[index].text = char(event.keycode)
				index += 1
				update_cursor()

	# Backspace (action: "back")
	if Input.is_action_pressed("back"):
		var row_start := current_row * MAX_LEN
		if index > row_start:
			index -= 1
			buttons[index].text = ""
			update_cursor()

	# Enter (action: "enter")
	if Input.is_action_pressed("enter"):
		submit_current_row()

func submit_current_row():
	var row_start := current_row * MAX_LEN
	var guess_len := index - row_start

	if guess_len < MIN_LEN:
		return

	# Sastavi guess (1–5 slova)
	var guess := ""
	for i in range(row_start, index):
		guess += buttons[i].text

	# Oboj slova
	color_row_any_length(guess, row_start)
	
	
	# Pobjeda samo ako je identično
	if guess == wordle:
		clear_cursor()
		label.text = "You Won"
		word_label.text = "Correct Word: " + wordle
		menu.show()
		return

	# Sljedeći pokušaj
	current_row += 1
	if current_row >= ATTEMPTS:
		clear_cursor()
		label.text = "You Lost"
		word_label.text = "Correct Word: " + wordle
		menu.show()
		return

	index = current_row * MAX_LEN
	update_cursor()
	


func color_row_any_length(guess: String, row_start: int):
	var target_len := wordle.length()

	for i in range(guess.length()):
		var btn: Button = buttons[row_start + i]
		var g := guess[i]

		if i < target_len and g == wordle[i]:
			update_button_style(btn, Color.SEA_GREEN)   # zeleno
		elif g in wordle:
			update_button_style(btn, Color.CHOCOLATE)   # narandžasto
		else:
			update_button_style(btn, Color.CRIMSON)     # crveno

func reset_game():

	index = 0
	current_row = 0

	label.text = ""
	word_label.text = ""
	menu.hide()

	wordle = get_random_wordle()
	print("Wordle:", wordle)

	for b in buttons:
		init_button_styles(b)
		
	cursor.visible = true
	cursor_timer.start()
	update_cursor()
	
	


func init_button_styles(b: Button):
	b.text = ""
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	#style.border_color = Color.DIM_GRAY
	style.border_color = Color(0, 0, 0, 0)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	b.add_theme_stylebox_override("normal", style)

func update_button_style(button: Button, bg_color: Color):
	var style := button.get_theme_stylebox("normal")
	style.bg_color = bg_color
	button.add_theme_stylebox_override("normal", style)

func get_random_wordle() -> String:
	var file := FileAccess.open("res://Scripts/MiniGames/WordleGame/wordle-list.txt", FileAccess.READ)
	var content := file.get_as_text(true)
	var lines := content.split("\n")

	var filtered: Array[String] = []
	for line in lines:
		var w := line.strip_edges()
		if w == "":
			continue
		# ciljna riječ 1–5 slova
		if w.length() >= MIN_LEN and w.length() <= MAX_LEN:
			filtered.append(w)

	randomize()
	return filtered.pick_random().to_upper()

func _on_button_pressed():
	reset_game()
	cursor.visible = true
	cursor_timer.start()
	update_cursor()
