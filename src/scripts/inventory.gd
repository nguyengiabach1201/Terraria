extends Node2D

@export var slotSprites: Array[Sprite2D]
@export var selectedSlotImage: Texture2D
@export var unselectedSlotImage: Texture2D

@export var player: CharacterBody2D

@export var itemSpriteForMouse: Sprite2D

var currentSelected: int
var items: Array[String] = ["", "", "", "","", "", "", ""]
var numbers: Array[int] = [0,0,0,0,0,0,0,0]

var placeableTile := ["dirt", "stone", "plank"]

var itemSprite = {
	"dirt": load("res://imgs/Tiles/dirt.png"),
	"stone": load("res://imgs/Tiles/stone.png"),
	"plank": load("res://imgs/Tiles/wood.png")
}

var clickedSpriteIndex: int
var closestSpriteIndex: int

func _ready():
	currentSelected = len(items) - 1
	for i in len(items):
		setItemSprite(i)
	
	updateInventory()
	setSelectedSlot()

func _process(_delta):
	if not player.isNotSelectingItem and items[clickedSpriteIndex] != "":
		itemSpriteForMouse.visible = true
		itemSpriteForMouse.texture = itemSprite[items[clickedSpriteIndex]]
		itemSpriteForMouse.position = get_viewport().get_mouse_position()
	elif player.isNotSelectingItem:
		itemSpriteForMouse.visible = false

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if currentSelected < len(items) - 1:
					currentSelected += 1
				else:
					currentSelected = 0
				setSelectedSlot()
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if currentSelected > 0:
					currentSelected -= 1
				else:
					currentSelected = len(items) - 1
				setSelectedSlot()
			if event.button_index == MOUSE_BUTTON_LEFT:
				clickedSpriteIndex = -1
				for i in len(slotSprites):
					if (slotSprites[i].position + get_viewport_rect().size - Vector2(512,512)).distance_to(get_viewport().get_mouse_position()) < 18:
						clickedSpriteIndex = i
						player.isNotSelectingItem = false
						break
		
		if event.is_released():
			if event.button_index == MOUSE_BUTTON_LEFT and not player.isNotSelectingItem:
				
				closestSpriteIndex = -1
				for i in len(slotSprites):
					if (slotSprites[i].position + get_viewport_rect().size - Vector2(512,512)).distance_to(get_viewport().get_mouse_position()) < 18:
						closestSpriteIndex = i
						break
				
				if clickedSpriteIndex != -1 and closestSpriteIndex != -1 and clickedSpriteIndex != closestSpriteIndex:
					if items[closestSpriteIndex] == items[clickedSpriteIndex]:
						numbers[closestSpriteIndex] += numbers[clickedSpriteIndex]
						numbers[clickedSpriteIndex] = 0
					if items[closestSpriteIndex] != items[clickedSpriteIndex]:
						items[closestSpriteIndex] = items[clickedSpriteIndex]
						numbers[closestSpriteIndex] = numbers[clickedSpriteIndex]
						numbers[clickedSpriteIndex] = 0
					
					currentSelected = closestSpriteIndex
					setSelectedSlot()
					updateInventory()
				
				if clickedSpriteIndex == closestSpriteIndex:
					currentSelected = closestSpriteIndex
					setSelectedSlot()
				
				player.isNotSelectingItem = true

func setSelectedSlot():
	for slot in slotSprites:
		slot.texture = unselectedSlotImage
	slotSprites[currentSelected].texture = selectedSlotImage

func setItemSprite(slotIndex):
	if itemSprite.has(items[slotIndex]):
		slotSprites[slotIndex].get_children()[0].texture = itemSprite[items[slotIndex]]

func updateInventory():
	for i in len(items):
		if numbers[i] <= 0:
			items[i] = ""
			slotSprites[i].get_children()[0].texture = null
			slotSprites[i].get_children()[1].text = ""
		else:
			setItemSprite(i)
			slotSprites[i].get_children()[1].text = str(numbers[i])
