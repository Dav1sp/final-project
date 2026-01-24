extends Node3D

@export_group("mesh")

@export var deadbody: MeshInstance3D
@export var alivebody: MeshInstance3D
@export var appear: float

var change = false

func _ready():
	# Garante que começa no estado certo
	deadbody.show()
	alivebody.hide()
	
func _process(delta):
	if GameData.progress >= self.appear and self.change == false:
		mudar_para_vivo()

func mudar_para_vivo():
	deadbody.hide()
	alivebody.show()
	self.change = true # Marca como feito para não repetir o processo
