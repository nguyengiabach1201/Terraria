extends Node

var rnd = RandomNumberGenerator.new()
var noise = FastNoiseLite.new()

var terrainTileMap: TileMap

@export var player: CharacterBody2D
@export var camera: Camera2D

var renderSize := Vector2(1,1)

var activeChunks: Array[Vector2] = []
var oldActiveChunks: Array[Vector2] = []
var oldChunk: Vector2

var suddenDraw: bool = false

var terrainMap: Array = []
var backgroundMap: Array = []

var lightMap: Array = []
var hasLightCalculated: Array = []

var background: Node2D

var playerSprite: Sprite2D
var playerSpawnPosition: Vector2i

var tileType = {
	"null": "null",
	
	"dirt": "dirt",
	"backgroundDirt":"backgroundDirt",
	"grass": "grass",
	
	"stone": "stone",
	"backgroundStone": "backgroundStone",
	"ironOre": "ironOre",
	"diamondOre": "diamondOre",
	
	"root": "root",
	"trunk": "trunk",
	"plank": "plank",
	
	"leaf": "leaf",
	"fern1":"fern1",
	"fern2":"fern2",
	"fern3":"fern3",
	"fern4":"fern4",
}

var tilePosition = {
	"null": Vector2i(8,7),
	
	"dirt": Vector2i(7,5),
	"grass": Vector2i(7,4),
	"backgroundDirt": Vector2i(6,0),
	
	"stone": Vector2i(3,4),
	"ironOre": Vector2i(2,0),
	"diamondOre": Vector2i(2,9),
	"backgroundStone": Vector2i(5,9),
	
	#"root": Vector2i(1,2),
	#"trunk": Vector2i(1,1),
	"plank": Vector2i(0,1),
	"root": Vector2i(1,0),
	"trunk": Vector2i(1,0),
	
	"leaf": Vector2i(4,8),
	"fern1": Vector2i(6,4),
	"fern2": Vector2i(6,5),
	"fern3": Vector2i(6,6),
	"fern4": Vector2i(6,7),
}

var tileBlockLight: Array[String] = ["dirt", "grass", "plank", "stone", "ironOre", "diamondOre", "plank"]

var tileSize = 128
#var width = 512; var height = 256
var width = 1024 + 2; var height = 512 + 2
#var width = 110 * 16 + 2; var height = 56*16 + 2
#var width = 48 + 2; var height = 48 + 2
var chunkSize = tileSize * 8
#var chunkSize = 128 * 12

var seed: int
@export var smoothness: float
@export var modifier: float

@export var ironRarity: float
@export var diamondRarity: float

func _ready():
	seed = rnd.randf() * 999999
	terrainTileMap = $TerrainTileMap as TileMap
	
	background = $Background as Node2D
	
	generate()
	
	player.set_position(playerSpawnPosition)
	camera.position = playerSpawnPosition
	
	background.position = playerSpawnPosition
	#background.position.x = playerSpawnPosition.x
	#background.position.y = height * tileSize
	
	activeChunks = getActiveChunks()
	oldActiveChunks = activeChunks
	
	getLightMap(activeChunks)
	
	resize()
	get_tree().get_root().size_changed.connect(resize)
	
	for child in player.get_children():
		if child is Sprite2D: 
			playerSprite = child
			break

func resize():
	suddenDraw = true
	
	if get_viewport().size.x >= get_viewport().size.y:
		renderSize.y = 1
		renderSize.x = ceil(renderSize.y * get_viewport().size.x / float(get_viewport().size.y))
	if get_viewport().size.x < get_viewport().size.y:
		renderSize.x = 1
		renderSize.y = ceil(renderSize.x * get_viewport().size.y / float(get_viewport().size.x))

func _process(delta):
	#print(Engine.get_frames_per_second())
	
	modulatePlayer()
	
	if getChunk() != oldChunk or suddenDraw:
		activeChunks = getActiveChunks()
		getLightMap(activeChunks)
		
		terrainTileMap.clear()
		for chunk in activeChunks:
			renderChunk(chunk)
		
		oldChunk = getChunk()
		oldActiveChunks = activeChunks
		
		suddenDraw = false

func generate():
	var wasTree := false
	var trees: Array[Vector2]
	
	for x in width:
		var noiseHeight: int = int(noise.get_noise_2d(x / smoothness, seed) * height / 2)
		noiseHeight += int(height / 2)
		
		if int(width / 2) == x:
			playerSpawnPosition = Vector2(x * tileSize - tileSize / 2, (height - noiseHeight) * tileSize - tileSize / 2)
		
		terrainMap.append([])
		backgroundMap.append([])
		
		lightMap.append([])
		hasLightCalculated.append(false)
		
		for y in height:
			#Lightmap
			lightMap[x].append(6)
			
			if y > height - noiseHeight:
				noise.frequency = 0.02
				var caveNoise = int(noise.get_noise_2d(x + seed, y + seed) / modifier)
				noise.frequency = 0.01
				var dirtLayerHeight = rnd.randf() * 3
				
				if caveNoise == 1: 
					#Cave
					terrainMap[x].append(tileType["null"])
					backgroundMap[x].append(tileType.backgroundStone)
				elif y > height - noiseHeight + 5 + dirtLayerHeight: 
					#Stone
					terrainMap[x].append(tileType.stone)
					backgroundMap[x].append(tileType.backgroundStone)
					
					#Ores
					noise.frequency = 0.075
					
					#Iron
					var ironNoise = int(noise.get_noise_2d(x + seed, y + seed) * 10 * ironRarity)
					if ironNoise:
						terrainMap[x][y] = tileType.ironOre
						backgroundMap[x][y] = tileType.backgroundStone
					
					#Diamond
					if y > height - noiseHeight + noiseHeight * 3 / 4:
						noise.frequency = 0.1
						var diamondNoise = int(noise.get_noise_2d(x + seed, y + seed) * 10 * diamondRarity)
						if diamondNoise:
							terrainMap[x][y] = tileType.diamondOre
							backgroundMap[x][y] = tileType.backgroundStone
					
					noise.frequency = 0.01
				else:
					#Grass
					if y == height - noiseHeight + 1:
						terrainMap[x].append(tileType.grass)
						backgroundMap[x].append(tileType.backgroundDirt)
						
						#Tree
						if !wasTree and x > 0 and x < width - 1:
							var treePosibility = rnd.randi_range(0,4)
							if treePosibility == 0:
								wasTree = true
								trees.append(Vector2(x,y))
						else: 
							wasTree = false
						
						#Fern
						var grassPosibility = rnd.randi_range(0,2)
						if grassPosibility == 0:
							var grassType = rnd.randi_range(1,4)
							terrainMap[x][y-1] = tileType["fern"+str(grassType)]
					#Dirt
					else: 
						terrainMap[x].append(tileType.dirt)
						backgroundMap[x].append(tileType.backgroundDirt)
			else: 
				#Nothing
				terrainMap[x].append(tileType["null"])
				backgroundMap[x].append(tileType["null"])
				
				lightMap[x][y] = 0
			
	for tree in trees:
		var treeHeight = rnd.randi_range(3,10)
		if terrainMap[tree.x][tree.y-treeHeight-2] == tileType["null"]:
			terrainMap[tree.x][tree.y-1] = tileType.root
			for leafX in range(-1,1+1):
				for leafY in range(-1,1+1):
					terrainMap[tree.x+leafX][tree.y-treeHeight-1+leafY] = tileType.leaf
			for trunkIndex in treeHeight - 2:
				terrainMap[tree.x][tree.y-2-trunkIndex] = tileType.trunk

func getChunk():
	var currentChunk := Vector2()
	currentChunk.x = floor((player.position.x + tileSize) / chunkSize)
	currentChunk.y = floor((player.position.y + tileSize) / chunkSize)

	currentChunk.x = clamp(currentChunk.x, 0, width * tileSize / chunkSize - 1)
	currentChunk.y = clamp(currentChunk.y, 0, height * tileSize / chunkSize - 1)
	
	return currentChunk

func getActiveChunks():
	var chunks: Array[Vector2] = []
	for x in range(-renderSize.x,renderSize.x+1):
		for y in range(-renderSize.y,renderSize.y+1):
			var chunk :Vector2 = getChunk()
			chunk.x += x; chunk.y += y
			if (clamp(chunk.y, 0, height * tileSize / chunkSize - 1) == chunk.y
				and clamp(chunk.x, 0, width * tileSize / chunkSize - 1) == chunk.x
			):
				chunks.append(chunk)
	return chunks

func renderChunk(chunk: Vector2):
	for x in range(chunk.x * chunkSize / tileSize, (chunk.x + 1) * chunkSize / tileSize):
		for y in range(chunk.y * chunkSize / tileSize, (chunk.y + 1) * chunkSize / tileSize):
			terrainTileMap.set_cell(lightMap[x][y], Vector2i(x,y), 0, tilePosition[backgroundMap[x][y]])
			if terrainMap[x][y] != "null":
				terrainTileMap.set_cell(lightMap[x][y], Vector2i(x,y), 0, tilePosition[terrainMap[x][y]])

func getLightMap(chunks):
	for x in range(chunks[0].x * chunkSize / tileSize, (chunks[len(chunks)-1].x + 1) * chunkSize / tileSize):
		var light: float = lightMap[x][(chunks[0].y-1) * chunkSize / tileSize]
		var beingBlocked := false
		
		for y in range(chunks[0].y * chunkSize / tileSize, (chunks[len(chunks)-1].y + 1) * chunkSize / tileSize):
			if terrainMap[x][y] in tileBlockLight:
				beingBlocked = true
				light += 1
			elif backgroundMap[x][y] != "null":
				beingBlocked = true
				light += 0.25
			elif beingBlocked:
				light += 0.25
			
			if backgroundMap[x][y] == "null" and terrainMap[x][y] == "null":
				light -= 0.5
			
			light = clamp(light,0,6)
			lightMap[x][y] = int(light)
			
			if lightMap[x][y] + 1 < lightMap[x-1][y]:
				lightMap[x-1][y] = lightMap[x][y] + 1
			
			if lightMap[x][y] > lightMap[x-1][y] + 1:
				lightMap[x][y] = lightMap[x-1][y] + 1

func modulatePlayer():
	var surround: Array
	for x in range(-2,2+1):
		for y in range(-2,2+1):
			if (
				int(player.position.x / tileSize) + x >= 0
				and int(player.position.x / tileSize) + x < width
				and int(player.position.y / tileSize) + y >= 0
				and int(player.position.y / tileSize) + y < height
				):
				surround.append(lightMap[int(player.position.x / tileSize) + x][int(player.position.y / tileSize) + y])
	
	var average = 0
	for s in surround: average += s
	
	average /= float(len(surround))
	average = (8-average)/float(8)
	playerSprite.modulate = Color(average,average,average)
