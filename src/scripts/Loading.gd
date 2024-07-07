extends Node2D

@export var main: PackedScene

func _process(delta):
	get_tree().change_scene_to_packed(main)
