extends Node2D

@onready var grid: GridContainer = $GridContainer
@onready var menu: CanvasLayer = $Menu

@onready var label: Label = $Menu/ResultLabel
@onready var word_label: Label = $Menu/WordLabel
@onready var cursor: ColorRect = $Cursor
@onready var cursor_timer: Timer = $CursorTimer

# Podesavanja igre
const MAX_LEN := 10       # broj polja po pokušaju (kod tebe je 10)
const ATTEMPTS := 5       # broj pokušaja
const MIN_LEN := 1        # minimum unesenih karaktera da bi Enter radio
var cursor_slot_valid := false
const CURSOR_HEIGHT := 70

# Dugmad u gridu (tipizirano)
var buttons: Array[Button] = []

# Game state
var wordle: String = ""
var index := 0
var current_row := 0

enum Lang { EN, IT, PT, ME, JP_HIRA }
var current_lang: Lang = Lang.EN

# 1) Šta smije da se ukuca (NE zavisi od word-lista)
const ALPHABET := {
	Lang.EN: "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	Lang.IT: "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÈÉÌÍÒÓÙÚ",
	Lang.PT: "ABCDEFGHIJKLMNOPQRSTUVWXYZÁÀÂÃÇÉÊÍÓÔÕÚÜ",
	Lang.ME: "ABCDEFGHIJKLMNOPQRSTUVWXYZČĆĐŠŽŚŹ",
	# Hiragana (osnovni set + ー)
	Lang.JP_HIRA: "ぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞ"
		+ "ただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽ"
		+ "まみむめもゃやゅゆょよらりるれろゎわをんー"
}

# 2) Rječnik (validne riječi) po jeziku
const WORDLIST_PATH := {
	Lang.EN: "res://Scripts/MiniGames/WordleGame/wordle-en.txt",
	Lang.IT: "res://Scripts/MiniGames/WordleGame/wordle-it.txt",
	Lang.PT: "res://Scripts/MiniGames/WordleGame/wordle-pt.txt",
	Lang.ME: "res://Scripts/MiniGames/WordleGame/wordle-me.txt",
	Lang.JP_HIRA: "res://Scripts/MiniGames/WordleGame/wordle-jp.txt" # kod tebe je ovako nazvan
}

var allowed_chars: Dictionary = {}   # char -> true
var words_set: Dictionary = {}       # word -> true  (za provjeru postoji li u rječniku)
var words_list: Array[String] = []   # za random target

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

	
	for b in buttons:
		b.focus_mode = Control.FOCUS_NONE

	set_language(Lang.PT) #SET LANGUAGE
	reset_game()

func update_cursor():
	var row_start := current_row * MAX_LEN
	var row_end := row_start + MAX_LEN

	
	cursor_slot_valid = (index >= row_start and index < row_end and index < buttons.size())

	if not cursor_slot_valid:
		cursor.visible = false
		return

	var btn := buttons[index]
	var rect := btn.get_global_rect()

	cursor.global_position = Vector2(
		rect.position.x + rect.size.x / 2 - cursor.size.x / 2,
		rect.position.y + (rect.size.y - CURSOR_HEIGHT) / 2
	)
	cursor.size.y = CURSOR_HEIGHT
	cursor.visible = true

func clear_cursor():
	cursor.visible = false
	cursor_timer.stop()


func _unhandled_key_input(event):
	if menu.visible:
		return

	if event is InputEventKey and event.is_pressed() and not event.echo:
		
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			submit_current_row()
			return

		# BACKSPACE
		if event.keycode == KEY_BACKSPACE:
			var row_start := current_row * MAX_LEN
			if index > row_start:
				index -= 1
				buttons[index].text = ""
				update_cursor()
			return

		
		if event.unicode > 0:
			var ch := String.chr(event.unicode)

			
			if ch == " " or ch == "\n" or ch == "\t":
				return

			
			if not allowed_chars.has(ch):
				return

			
			if current_lang != Lang.JP_HIRA:
				ch = ch.to_upper()

			var row_end := (current_row + 1) * MAX_LEN
			if index < row_end and index < buttons.size():
				buttons[index].text = ch
				index += 1
				update_cursor()

func submit_current_row():
	var row_start := current_row * MAX_LEN
	var guess_len := index - row_start

	if guess_len < MIN_LEN:
		return

	
	var guess := ""
	for i in range(row_start, index):
		guess += buttons[i].text

	
	if current_lang != Lang.JP_HIRA:
		guess = guess.to_upper()

	

	var is_valid := words_set.has(guess)
	
	color_row_any_length(guess, row_start)

	if not is_valid:
		
		label.text = "Nije u rječniku"
		color_invalid_row(current_row)
		advance_row()
		return

	
	color_row_any_length(guess, row_start)

	
	if guess == wordle:
		clear_cursor()
		label.text = "You Won"
		word_label.text = "Correct Word: " + wordle
		menu.show()
		return

	
	advance_row()

func advance_row() -> void:
	current_row += 1
	if current_row >= ATTEMPTS:
		clear_cursor()
		label.text = "You Lost"
		word_label.text = "Correct Word: " + wordle
		menu.show()
		return

	index = current_row * MAX_LEN
	update_cursor()

func color_invalid_row(row: int) -> void:
	var start := row * MAX_LEN
	var end := start + MAX_LEN
	for i in range(start, end):
		if i >= 0 and i < buttons.size():
			buttons[i].modulate = Color(0.4, 0.4, 0.4, 1.0)

func color_row_any_length(guess: String, row_start: int):
	var target_len := wordle.length()

	for i in range(guess.length()):
		var btn: Button = buttons[row_start + i]
		var g := guess[i]

		if i < target_len and g == wordle[i]:
			update_button_style(btn, Color.SEA_GREEN)   
		elif g in wordle:
			update_button_style(btn, Color.CHOCOLATE)  
		else:
			update_button_style(btn, Color.CRIMSON)     

func set_language(lang: Lang) -> void:
	current_lang = lang

	# allowed chars
	allowed_chars.clear()
	var a: String = ALPHABET[current_lang]
	for ch in a:
		allowed_chars[ch] = true
		allowed_chars[ch.to_lower()] = true

	_load_words()

func _load_words() -> void:
	words_set.clear()
	words_list.clear()

	var path: String = WORDLIST_PATH[current_lang]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open word list: " + path)
		return

	var lines := file.get_as_text(true).split("\n")
	for line in lines:
		var w := line.strip_edges()
		if w == "":
			continue

		
		if current_lang != Lang.JP_HIRA:
			w = w.to_upper()

		if w.length() >= MIN_LEN and w.length() <= MAX_LEN:
			words_set[w] = true
			words_list.append(w)

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
		b.modulate = Color(1, 1, 1, 1) # reset modulate 

	cursor.visible = true
	cursor_timer.start()
	update_cursor()

func init_button_styles(b: Button):
	b.text = ""
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
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
	if words_list.is_empty():
		return ""
	randomize()
	return words_list.pick_random()

func _on_button_pressed():
	reset_game()
	cursor.visible = true
	cursor_timer.start()
	update_cursor()
