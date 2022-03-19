extends TileMap

onready var Automaton = Game.Automaton
onready var Neighborhood = Game.Neighborhood
onready var Initial = Game.Initial
onready var x_max = Game.X_MAX

var next_row = 0

const GENERATION_SPEED = 20000 # generate at max this many rows per second
const Y_BUFFER = 80
const QUANT = 0.1
const DEFAULT_VOLUME = -15

var t = 0
var music_frame = 0
var note_length = 0
var music_level = 0

var binary_rule = ""

var change_history = []

func initialize_level():
	clear()
	$Beep.stop()
	$Boop.stop()
	music_frame = 0
	t = 0
	note_length = 0 
	
	binary_rule = Big.bin(Game.rule)
	
	# first row
	for x in range(0, x_max):
		if Game.initial == Initial.POINT:
			set_cell(x, 0, 0)
		elif Game.initial == Initial.RANDOM:
			set_cell(x, 0, randi() % 2)
	set_cell((x_max-1)/2, 0, 1)
		
	for y in range(1, 100):#Game.player.max_depth + Y_BUFFER):
		generate_row(y)
	next_row = Game.player.max_depth + Y_BUFFER
	
func generate_row(y):
	var neighborhood
	var automaton
	var rule
	
	if Game.story:
		var data = Game.map.get_data(y)
		if not data:
			for x in range(0, x_max):
				set_cell(x, y, 2)
			return
		
		automaton = data[0]
		neighborhood = data[1]
		rule = data[2]
		
	else:
		automaton = Game.automaton
		neighborhood = Game.neighborhood
		rule = binary_rule
		
	for x in range(0, x_max):
		var neighbors
		
		if neighborhood == Neighborhood.NEAREST_NEIGHBOR:
			neighbors = [
				get_cell((x-1+x_max) % x_max, y-1),
				get_cell(x, y-1),
				get_cell((x+1) % x_max, y-1)
			]
			
		elif neighborhood == Neighborhood.FIVE_CELL:
			neighbors = [
				get_cell((x-2+x_max) % x_max, y-1),
				get_cell((x-1+x_max) % x_max, y-1),
				get_cell(x, y-1),
				get_cell((x+1) % x_max, y-1),
				get_cell((x+2) % x_max, y-1),
			]
			
		elif neighborhood == Neighborhood.TWO_STEP:
			if y == 1:
				neighbors = [0, 0, 0,
					get_cell((x-1+x_max) % x_max, y-1),
					get_cell(x, y-1),
					get_cell((x+1) % x_max, y-1),
				]
			else:
				neighbors = [
					get_cell((x-1+x_max) % x_max, y-2),
					get_cell(x, y-2),
					get_cell((x+1) % x_max, y-2),
					get_cell((x-1+x_max) % x_max, y-1),
					get_cell(x, y-1),
					get_cell((x+1) % x_max, y-1),
				]
				
		elif neighborhood == Neighborhood.FIVE_CELL_TWO_STEP:
			if y == 1:
				neighbors = [0, 0, 0, 0, 0,
					get_cell((x-2+x_max) % x_max, y-1),
					get_cell((x-1+x_max) % x_max, y-1),
					get_cell(x, y-1),
					get_cell((x+1) % x_max, y-1),
					get_cell((x+2) % x_max, y-1),
				]
			else:
				neighbors = [
					get_cell((x-2+x_max) % x_max, y-2),
					get_cell((x-1+x_max) % x_max, y-2),
					get_cell(x, y-2),
					get_cell((x+1) % x_max, y-2),
					get_cell((x+2) % x_max, y-2),
					get_cell((x-2+x_max) % x_max, y-1),
					get_cell((x-1+x_max) % x_max, y-1),
					get_cell(x, y-1),
					get_cell((x+1) % x_max, y-1),
					get_cell((x+2) % x_max, y-1),
				]
		
		var bit = 0
		if automaton == Automaton.CLASSIC:
			for i in range(0, neighbors.size()):
				bit += neighbors[i] * pow(2, neighbors.size() - 1 - i)
				
		elif automaton == Automaton.TOTALISTIC:
			for neighbor in neighbors:
				bit += neighbor
		
		# choose the cell (based on the corresponding bit of the rule)
		# (rule >> bit) & 1
		var new_cell = int(rule.substr(rule.length()-1-bit, 1))
		set_cell(x, y, new_cell)
			
func collided(collision):
	if collision.collider == self:
		var tile_pos = world_to_map(collision.position)
		var tile = get_cellv(tile_pos)
		if tile == 2 and Game.story:
			Game.hit_bottom()

func build(position):
	if get_cell(position.x, position.y + 1) == 0:
		set_cell(position.x, position.y + 1, 1)
		if Game.story:
			change_history.append(["BUILD", position])
	
func bomb(position):
	var directions = [
		[5, 2],
		[4, 3],
		[3, 4],
		[2, 5],
		[1, 5],
		[0, 5]
	]
	var tile_pos = world_to_map(position)
	for d in directions:
		for x in range(-d[1], d[1]+1):
			x = (int(tile_pos.x) + x + Game.X_MAX) % Game.X_MAX
			if get_cell(x, tile_pos.y + d[0]) == 1:
				set_cell(x, tile_pos.y + d[0], 0)
			if get_cell(x, tile_pos.y - d[0]) == 1:
				set_cell(x, tile_pos.y - d[0], 0)
	if Game.story:
		change_history.append(["BOMB", position])

func redo_changes(history):
	for change in history:
		if change[0] == "BUILD":
			build(change[1])
		elif change[0] == "BOMB":
			bomb(change[1])
			
func _process(delta):
	if not Game.started:
		return
	t += delta
	
	# generate rows
	var target = Game.player.max_depth + Y_BUFFER # how far we'd like to generate to maintain a buffer below the player
	var limit = int(next_row + GENERATION_SPEED * delta) # how far we can afford to generate without lagging the game
	while next_row < target and next_row < limit:
		generate_row(next_row)
		next_row += 1
	
	# play music	
	while t > music_frame * QUANT:
		if Game.story:
			var player_level = int(Game.player.position.y) - (int(Game.player.position.y) % Game.map.LEVEL_DEPTH)
			if player_level != music_level:
				music_level = player_level
				music_frame = 0
				t = 0
		var y = floor(music_frame / x_max) * 10+1
		if Game.story:
			y += music_level
		var x = music_frame % x_max
		var music1 =\
			get_cell(x, y) * 16 +\
			get_cell(x, y+1) * 8 +\
			get_cell(x, y+2) * 4 +\
			get_cell(x, y+3) * 2 +\
			get_cell(x, y+4)
		var music2 = \
			get_cell(x, y+5) * 16 +\
			get_cell(x, y+6) * 8 +\
			get_cell(x, y+7) * 4 +\
			get_cell(x, y+8) * 2 +\
			get_cell(x, y+9)
		
		if music1 == 0:
			$Beep.stop()
		else:
			$Beep.volume_db = DEFAULT_VOLUME - music1 / 4
			$Beep.pitch_scale = pow(2, music1 / 15.5) #* 0.8
			if not $Beep.playing:
				$Beep.play()
				
		if music2 == 0:
			$Boop.stop()
		else:
			$Boop.volume_db = DEFAULT_VOLUME + (31-music2) / 4
			$Boop.pitch_scale = pow(2, music2 / 15.5 - 2) #* 0.8
			if not $Boop.playing:
				$Boop.play()
		music_frame += 1
	
