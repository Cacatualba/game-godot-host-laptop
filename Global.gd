extends Node
var GameStarted: bool

@export var player: CharacterBody2D
var PlayerWeaponEquip: bool

var PlayerAlive: bool
var PlayerDamagedZone: Area2D
var PlayerDamageAmount: int
@export var SavedPlayerPosition: Vector2


#func _physics_process(delta):
	#if Input.is_action_just_pressed("Option_In_Game"):
	#	Global.SavedPlayerPosition = player.global_position
		#GLobal.has_saved_position = true
		#get_tree().change_scene_to_file(
		#	"res://scene/option in game/Option_In_Game.tscn"
	#	)
