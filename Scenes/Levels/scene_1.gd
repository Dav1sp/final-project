extends Node3D
@onready var light_dark = $DirectionalLight3D
@onready var light_sun = $DirectionalLight3D2
@onready var sea_waves: AudioStreamPlayer = $Sound_group/sea_waves
@onready var dead_zone_1: Node3D = $deadZone_1
@onready var alive_zone_1: Node3D = $aliveZone_1
@export var appear: float = 50
var change = false
var first_enter = false

func _ready():
	dead_zone_1.show()
	alive_zone_1.ativar_grupo(false)
	return

func _process(delta):
	if GameData.progress >= self.appear and self.change == false:
		mudar_para_vivo()

func mudar_para_vivo():
	dead_zone_1.hide()
	alive_zone_1.ativar_grupo(true)
	self.change = true # Marca como feito para não repetir o processo

func _on_iteract_range_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		if first_enter:
			light_dark.hide()
			light_sun.show()
			print('enter')
			$Sound_group/submerge.stop()
			$Sound_group/underwater.stop()
			$Sound_group/merge.pitch_scale = 2.0
			$Sound_group/merge.play()
			sea_waves.play()
		else:
			first_enter = true
			light_dark.hide()
			light_sun.show()
			sea_waves.play()
			
	

func _on_iteract_range_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		print('leave')
		sea_waves.stop()
		$Sound_group/merge.stop()
		light_dark.show()
		light_sun.hide()
		$Sound_group/submerge.pitch_scale = 2.0
		$Sound_group/submerge.play()
		await $Sound_group/submerge.finished
		$Sound_group/underwater.play()
