extends Node2D

@export var background: Node2D
var backgroundSpeed := 10.0

@export var load: PackedScene

func _ready():
	DisplayServer.window_set_min_size(Vector2(512,512))
	resize()
	get_tree().get_root().size_changed.connect(resize)

func _process(delta):
	background.position.x += backgroundSpeed * delta
	
	if background.position.x - position.x > 128:
		backgroundSpeed = -backgroundSpeed
	
	if background.position.x - position.x < -128:
		backgroundSpeed = -backgroundSpeed

func _on_start_button_button_up():
	get_tree().change_scene_to_packed(load)

func resize():
	#print(ceil(get_viewport().size.x / float(get_viewport().size.y)))
	background.scale.x = get_viewport().size.y / float(get_viewport().size.x)
	background.scale.y = background.scale.x
	pass
