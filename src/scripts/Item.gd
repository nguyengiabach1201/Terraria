extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player: CharacterBody2D

var type: String

func _physics_process(delta):
	if not is_on_floor() and player and position.distance_to(player.position) > 1:
		velocity.y += gravity * delta
	
	if player and position.distance_to(player.position) <= player.world.tileSize * 3:
		velocity += (player.position - position) / 5
		if position.distance_to(player.position) <= player.world.tileSize:
			for i in range(-len(player.inventory.items)+1,1):
				if player.loot.has(type) and player.loot[type] in player.inventory.items:
					if player.inventory.items[-i] == player.loot[type]:
						player.inventory.numbers[-i] += 1
						player.inventory.updateInventory()
						break
				elif player.inventory.items[-i] == "" and player.loot.has(type):
					player.inventory.numbers[-i] += 1
					player.inventory.items[-i] = player.loot[type]
					player.inventory.updateInventory()
					break
			
			player.soundPlayer.stream = player.audios["pick-up"]
			player.soundPlayer.play()
			
			queue_free()
	
	move_and_slide()
