extends CharacterBody2D

const speed = 600.0
#const jumpVelocity = -1000.0
const jumpVelocity = -700.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 1.25

var mousePosition: Vector2
var oldMousePosition: Vector2
var mouseTime: float

var currentTool # Axe, Sword, Pickaxe
var toolLevel # Wooden: 0, Rock: 1, Iron: 2, Diamond: 3

var breakTime = {
	"dirt": 1,
	"grass": 1,
	"stone": 10,
	"ironOre": 15,
	"diamondOre": 15,
	"root": 5,
	"trunk": 5,
	"plank": 5,
	"leaf": 0,
	"fern1": 0,
	"fern2": 0,
	"fern3": 0,
	"fern4": 0,
}

var audios = {
	"dirt-break": load("res://audios/Breaking/Dirt.ogg"),
	"dirt-place": load("res://audios/Placing/Dirt.ogg"),
	"wood-break": load("res://audios/Breaking/Wood.ogg"),
	"wood-place": load("res://audios/Placing/Wood.ogg"),
	"stone-break": load("res://audios/Breaking/Stone.ogg"), # No stone place sound
	"grass-break": load("res://audios/Breaking/Grass.ogg"), # No grass place sound
	"pick-up": load("res://audios/Picking.ogg"),
}

var breakAudio = {
	"dirt": audios["dirt-break"],
	"grass": audios["dirt-break"],
	"stone": audios["stone-break"],
	"ironOre": audios["stone-break"],
	"diamondOre": audios["stone-break"],
	"root": audios["wood-break"],
	"trunk": audios["wood-break"],
	"plank": audios["wood-break"],
	"leaf": audios["grass-break"],
	"fern1": audios["grass-break"],
	"fern2": audios["grass-break"],
	"fern3": audios["grass-break"],
	"fern4": audios["grass-break"],
}

var placeAudio = {
	"dirt": audios["dirt-place"],
	"grass": audios["dirt-place"],
	"stone": audios["dirt-place"],
	"ironOre": audios["dirt-place"],
	"diamondOre": audios["dirt-place"],
	"root": audios["wood-place"],
	"trunk": audios["wood-place"],
	"plank": audios["wood-place"],
}

var loot = {
	"dirt": "dirt",
	"grass": "dirt",
	"stone": "stone",
	"ironOre": "",
	"diamondOre": "",
	"root": "plank",
	"trunk": "plank",
	"plank": "plank",
}

var breakAnimation = {
	"1": load("res://imgs/Breaking/state1.png"),
	"2": load("res://imgs/Breaking/state2.png"),
	"3": load("res://imgs/Breaking/state3.png"),
	"4": load("res://imgs/Breaking/state4.png"),
}

var dropItem = load("res://scenes/Item.tscn")

var isNotSelectingItem = true

@export var world: Node2D
@export var inventory: Node2D

@export var breakSprite: Sprite2D
@export var breakParticle: CPUParticles2D
@export var soundPlayer: AudioStreamPlayer

func _physics_process(delta):
	move(delta)
	
	if Input.is_mouse_button_pressed(1) and isNotSelectingItem:
		mouseTime += delta
		breakBlock()
		
		if oldMousePosition != mousePosition:
			mouseTime = 0
			breakSprite.position = Vector2(-world.tileSize, -world.tileSize)
	
	if Input.is_action_just_released("click"):
		mouseTime = 0
		breakSprite.position = Vector2(-world.tileSize, -world.tileSize)
	
	if Input.is_mouse_button_pressed(2):
		placeBlock()
	
	oldMousePosition = mousePosition
	#isNotSelectingItem = true

func move(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if Input.is_action_pressed("jump") and (is_on_floor() or position.y >= world.height * world.tileSize - world.tileSize / 2 - 3 *world.tileSize):
		velocity.y = jumpVelocity
	
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	move_and_slide()
	
	position.x = clamp(position.x, world.tileSize + world.tileSize / 2, world.width * world.tileSize - world.tileSize / 2 - 3 * world.tileSize)
	position.y = clamp(position.y, world.tileSize + world.tileSize / 2, world.height * world.tileSize - world.tileSize / 2 - 3 *world.tileSize)
	
	if !world.camera.position_smoothing_enabled: world.camera.position_smoothing_enabled = true
	
	#world.camera.position.x = position.x
	#world.camera.position.y = position.y
	world.camera.position.x = clamp(position.x, world.tileSize + get_viewport().get_visible_rect().size.x / world.camera.zoom.x / 2, world.width*world.tileSize - get_viewport().get_visible_rect().size.x / world.camera.zoom.x / 2 - 3 * world.tileSize)
	world.camera.position.y = clamp(position.y, world.tileSize + get_viewport().get_visible_rect().size.y / world.camera.zoom.y / 2, world.height*world.tileSize - get_viewport().get_visible_rect().size.y / world.camera.zoom.y / 2 - 3 * world.tileSize)
	
	if world.background.position.x - position.x < -3072:
		world.background.position.x += 3072
	
	if world.background.position.x - position.x > 3072:
		world.background.position.x -= 3072

func breakBlock():
	mousePosition.x = int(get_global_mouse_position().x / world.tileSize)
	mousePosition.y = int(get_global_mouse_position().y / world.tileSize)
	
	if breakAudio.has(world.terrainMap[mousePosition.x][mousePosition.y]):
		if not soundPlayer.is_playing() or oldMousePosition != mousePosition:
			soundPlayer.stream = breakAudio[world.terrainMap[mousePosition.x][mousePosition.y]]
			soundPlayer.play()
	
	if (
		breakTime.has(world.terrainMap[mousePosition.x][mousePosition.y])
		and mouseTime >= breakTime[world.terrainMap[mousePosition.x][mousePosition.y]]
		):
		
		if placeAudio.has(world.terrainMap[mousePosition.x][mousePosition.y]):
			soundPlayer.stream = placeAudio[world.terrainMap[mousePosition.x][mousePosition.y]]
			soundPlayer.play()
		
		if loot.has(world.terrainMap[mousePosition.x][mousePosition.y]):
			var instance = dropItem.instantiate()
			instance.player = self
			instance.type = world.terrainMap[mousePosition.x][mousePosition.y]
			instance.rotation = randi_range(0, 360)
			instance.position = Vector2((mousePosition.x + 0.5) * world.tileSize, (mousePosition.y + 0.5) * world.tileSize)
			instance.get_children()[0].texture = inventory.itemSprite[loot[world.terrainMap[mousePosition.x][mousePosition.y]]]
			world.add_child(instance)
			
			breakParticle.position = breakSprite.position
			breakParticle.texture = inventory.itemSprite[loot[world.terrainMap[mousePosition.x][mousePosition.y]]]
			breakParticle.emitting = true
		
		world.terrainMap[mousePosition.x][mousePosition.y] = "null"
		if world.terrainMap[mousePosition.x][mousePosition.y-1]:
			if "fern" in world.terrainMap[mousePosition.x][mousePosition.y-1]:
				world.terrainMap[mousePosition.x][mousePosition.y-1] = "null"
		
		world.suddenDraw = true
		
		mouseTime = 0
		breakSprite.position = Vector2(-world.tileSize, -world.tileSize)
	
	if breakTime.has(world.terrainMap[mousePosition.x][mousePosition.y]):
		var state: int = mouseTime * 4 / float(breakTime[world.terrainMap[mousePosition.x][mousePosition.y]]) + 1
		breakSprite.texture = breakAnimation[str(state)]
		breakSprite.position = Vector2((mousePosition.x + 0.5) * world.tileSize, (mousePosition.y + 0.5) * world.tileSize)

func placeBlock():
	mousePosition.x = int(get_global_mouse_position().x / world.tileSize)
	mousePosition.y = int(get_global_mouse_position().y / world.tileSize)
	
	if (
		world.tileType.has(inventory.items[inventory.currentSelected]) and
		inventory.items[inventory.currentSelected] in inventory.placeableTile and
		(
			world.terrainMap[mousePosition.x][mousePosition.y] == "null"
			or "fern" in world.terrainMap[mousePosition.x][mousePosition.y]
		)
		and (
				mousePosition.x - position.x / world.tileSize >= 0.5
				or mousePosition.x - position.x / world.tileSize <= -1.5
				or mousePosition.y - position.y / world.tileSize >= 0.4
				or mousePosition.y - position.y / world.tileSize <= -1.5
			)
		):
		
		if placeAudio.has(world.terrainMap[mousePosition.x][mousePosition.y]):
			soundPlayer.stream = placeAudio[world.terrainMap[mousePosition.x][mousePosition.y]]
			soundPlayer.play()
		
		world.terrainMap[mousePosition.x][mousePosition.y] = inventory.items[inventory.currentSelected]
		inventory.numbers[inventory.currentSelected] -= 1
		inventory.updateInventory()
		
		if world.terrainMap[mousePosition.x][mousePosition.y+1]:
			if world.terrainMap[mousePosition.x][mousePosition.y+1] == "grass":
				world.terrainMap[mousePosition.x][mousePosition.y+1] = "dirt"
		world.suddenDraw = true
