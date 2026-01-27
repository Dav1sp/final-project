extends CharacterBody3D

@export_group("Camera")
@export_range(0.0,1.0) var mouse_sensitivity := 0.25

@export_group("Movement")
@export var move_speed := 4.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0


var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.UP
var _gravity := -30.0
var input_enabled = true
var area = null
var minigame = false
var move_free = true
var load_move_free = true

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera:Camera3D = %Camera3D
@onready var _skin:Node3D = %mermaid

func ready():
	pass
func simulate_interact_action():
	# 1. Força o estado de "pressionado" na ação do Input Map
	Input.action_press("interact")
	
	# 2. No frame seguinte, solta a ação
	# Usamos idle_frame para garantir que o motor registou o "just_pressed"
	await get_tree().process_frame
	Input.action_release("interact")
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed('left_click') and !minigame and !GameManager.quiz:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed('ui_cancel'):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if DialogueManager.is_dialogue_active:
		return	
	if Input.is_action_just_pressed("interact") and area !=null and !minigame:
		if !move_free:
			move_free=true
		if(self.area.get_meta("type")):
			print('minijogo')
			match self.area.get_meta("type_minigame"):
				"slide_puzzle":
					if self.area.get_meta("grid") == 5 and !GameData.minijogos['puzzle_4']:
						var item_name = self.area.get_meta("name")
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'block',self.area)
						await DialogueManager.dialogue_finished
					elif self.area.get_meta("grid") == 6 and (!GameData.minijogos['puzzle_4'] or !GameData.minijogos['puzzle_5']):
						var item_name = self.area.get_meta("name")
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'block',self.area)
						await DialogueManager.dialogue_finished
					else:
						do_minigame()
				_:
					do_minigame()
			#self.area.get_meta("type_minigame")
			#GameData.minijogos['puzzle_4']
		else:
			print('item')
			colect_item()
			print('collection item')

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and 
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity

		
func _physics_process(delta: float) -> void:
	if !move_free:
		return
	if not input_enabled:
		return
	if DialogueManager.is_dialogue_active:
		return
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -PI/6.0, PI/3.0)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta

	_camera_input_direction = Vector2.ZERO
	
	var raw_input := Input.get_vector("move_left","move_right","move_up","move_down")
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	velocity.y = y_velocity + _gravity * delta
	move_and_slide()
	
	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction
	
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y,target_angle, rotation_speed * delta)
	
	var ground_speed := velocity.length()
	if ground_speed > 0.0:
		move()
	else:
		idle()
	if load_move_free:
		idle()
		load_move_free=false
		move_free=false
		return
	
func idle():
	_skin.get_node("AnimationPlayer").play("Idle")

func move():
	_skin.get_node("AnimationPlayer").play("Walk", 0.0, 1.5)
	
func body_enter_the_area(area_aux):
	self.area = area_aux
	print("enter")
	pass
	
func body_leave_the_area():
	self.area = null
	print("leave")
	pass

func do_minigame():
	if self.area == null:
		return
	var owner_node := self.area.get_parent() as Node3D
	owner_node.iteract.hide()
	var som = get_node("../Sound_group/underwater")
	match self.area.get_meta("type_minigame"):
		"slide_puzzle":
			GameManager.win=false
			var item_name = self.area.get_meta("name")
			if !self.area.get_meta("first_talk"):
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'first_dialogue',area)
				await DialogueManager.dialogue_finished
			else:
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'back',area)
				await DialogueManager.dialogue_finished
			self.minigame = true	
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			som.stop()
			input_enabled = false
			var path_to_load = self.area.get_meta("game").replace('"', '')
			var path_image = self.area.get_meta("path").replace('"', '')
			var game_scene = load(path_to_load).instantiate()
			game_scene.player = self
			game_scene.image_path = path_image
			game_scene.npc = owner_node
			game_scene.GRID = self.area.get_meta("grid")
			get_tree().current_scene.add_child(game_scene)
			await game_scene.tree_exited
			GameManager.win_label.hide()
			som.play()
			if GameManager.win:
				if self.area.get_meta("grid") == 4:
					if GameData.minijogos['puzzle_4']:
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'again',area)
						await DialogueManager.dialogue_finished
					else:
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'win',area)
						await DialogueManager.dialogue_finished
						GameData.minijogos['puzzle_4']=true
						GameData.progress+=6.25
						
				elif self.area.get_meta("grid") == 5:
					if GameData.minijogos['puzzle_5']:
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'again',area)
						await DialogueManager.dialogue_finished
					else:
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'win',area)
						await DialogueManager.dialogue_finished
						GameData.minijogos['puzzle_5']=true
						GameData.progress+=6.25
				elif self.area.get_meta("grid") == 6:
					if GameData.minijogos['puzzle_6']:
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'again',area)
						await DialogueManager.dialogue_finished
					else:
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'win',area)
						await DialogueManager.dialogue_finished
						GameData.minijogos['puzzle_6']=true
						GameData.progress+=6.25
			else:
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'leave',area)
				await DialogueManager.dialogue_finished
			owner_node.iteract.show()
		"breakout":
			GameManager.win=false
			var item_name = self.area.get_meta("name")
			if !self.area.get_meta("first_talk"):
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'first_dialogue',area)
				await DialogueManager.dialogue_finished
			else:
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'back',area)
				await DialogueManager.dialogue_finished
			self.minigame = true	
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			som.stop()
			input_enabled = false
			var path_to_load = self.area.get_meta("game").replace('"', '')
			GameManager.level = self.area.get_meta("level")
			var game_scene = load(path_to_load).instantiate()
			game_scene.npc = owner_node
			game_scene.player = self
			get_tree().current_scene.add_child(game_scene)
			await game_scene.tree_exited
			som.play()
			GameManager.win_label.hide()
			if GameManager.win:
				if(self.area.get_meta("level")==3):
					if GameData.minijogos['breakout_3']:
							DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'again',area)
							await DialogueManager.dialogue_finished
					else:
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'win',area)
						await DialogueManager.dialogue_finished
						GameData.minijogos['breakout_3']=true
						GameData.progress+=6.25
				else:
					if GameData.minijogos['breakout_6']:
							DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'again',area)
							await DialogueManager.dialogue_finished
					else:
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'win',area)
						await DialogueManager.dialogue_finished
						GameData.minijogos['breakout_6']=true
			else:
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'leave',area)
				await DialogueManager.dialogue_finished
			owner_node.iteract.show()
			GameManager.win_label.hide()
		"wordle":
			GameManager.win=false
			var item_name = self.area.get_meta("name")
			if !self.area.get_meta("first_talk"):
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'first_dialogue',area)
				await DialogueManager.dialogue_finished
			else:
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'back',area)
				await DialogueManager.dialogue_finished
			self.minigame = true	
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			som.stop()
			input_enabled = false
			var path_to_load = self.area.get_meta("game").replace('"', '')	
			var game_scene = load(path_to_load).instantiate()
			game_scene.npc = owner_node
			game_scene.player = self
			print(self.area.get_meta("words"))
			game_scene.wordle_array = [DialogueManager.get_dialogue_text('menu',self.area.get_meta("words")[0])[0],DialogueManager.get_dialogue_text('menu',self.area.get_meta("words")[1])[0],DialogueManager.get_dialogue_text('menu',self.area.get_meta("words")[2])[0]]
			get_tree().current_scene.add_child(game_scene)
			await game_scene.tree_exited
			som.play()
			GameManager.win_label.hide()
			if GameManager.win:
				if(self.area.get_meta("words")[0]=='fumo'):
					if GameData.minijogos['wordle_fumo']:
							DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'again',area)
							await DialogueManager.dialogue_finished
					else:
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'win',area)
						await DialogueManager.dialogue_finished
						GameData.minijogos['wordle_fumo']=true
						GameData.progress+=6.25
				else:
					if GameData.minijogos['wordle_raiz']:
							DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'again',area)
							await DialogueManager.dialogue_finished
					else:
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'win',area)
						await DialogueManager.dialogue_finished
						GameData.minijogos['wordle_raiz']=true
			else:
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'leave',area)
				await DialogueManager.dialogue_finished
			owner_node.iteract.show()
			GameManager.win_label.hide()
		"colect_trash":
			var item_name = self.area.get_meta("name")
			if !self.area.get_meta("first_talk"):
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'first_dialogue',area)
				await DialogueManager.dialogue_finished
				GameData.itens = true
			else:
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'end_dialogue',area)
				await DialogueManager.dialogue_finished
			owner_node.iteract.show()
		"lost_pearl":
			var item_name = self.area.get_meta("name")
			if !self.area.get_meta("first_talk"):
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'first_dialogue',area)
				await DialogueManager.dialogue_finished
				GameData.pearl= true
			else:
				if GameData.items_colect['pearl']:
					$"../NPCS/Ameijoa_pink_pearl/ameijoaup_003".show()
					DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'falar_com_perola',area)
					await DialogueManager.dialogue_finished
				else:
					DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'falar_sem_perola',area)
					await DialogueManager.dialogue_finished
			owner_node.iteract.show()
		"quiz":
			var item_name = self.area.get_meta("name")
			if !self.area.get_meta("first_talk"):
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'first_dialogue',area)
				await DialogueManager.dialogue_finished
				owner_node.iteract.show()
			else:
				if(GameData.progress==100.0):
					DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'end_dialogue',area)
					await DialogueManager.dialogue_finished
					var s1 = 0
					var s2 = 0
					for answer in GameData.first_quiz:
						if answer:
							s1+=1
					for answer in GameData.second_quiz:
						if answer:
							s2+=1
					var max_score = 6
	
					if s2 >= max_score and s1 >= (max_score - 1):
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'master',area)
						
					elif s2 > s1:
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'evolution',area)
						
					elif s2 < 3: # (Exemplo: acertou menos de metade)
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'failed',area)
						
					else:
						DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'evolution',area)
					await DialogueManager.dialogue_finished
					owner_node.iteract.show()
				else:
					DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'game_complete',area)
					await DialogueManager.dialogue_finished
					owner_node.iteract.show()
		_:
			var item_name = self.area.get_meta("name")
			if !self.area.get_meta("first_talk"):
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'first_dialogue',area)
				await DialogueManager.dialogue_finished
				owner_node.iteract.show()
			else:
				DialogueManager.show_dialogue("scene_intro", item_name, 1,null,'end_dialogue',area)
				await DialogueManager.dialogue_finished
				owner_node.iteract.show()
			print("nothing")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	self.input_enabled = true
	self.minigame = false	
	#owner_node.iteract.show()

func colect_item():
	if self.area == null:
		return
	var item_name = self.area.get_meta("name")
	var var_name = self.area.get_meta("name_var")
	GameData.items_colect[var_name] = true
	var objecto_pai = self.area.get_parent()
	objecto_pai.queue_free()
	self.area = null
	DialogueManager.show_dialogue("scene_intro", item_name, 0)
	GameData.progress+=6.25
	print(GameData.progress)
	pass
