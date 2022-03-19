extends TileMap

onready var Automaton = Game.Automaton
onready var Neighborhood = Game.Neighborhood
onready var Initial = Game.Initial
onready var x_max = Game.X_MAX

var next_row = 0

const GENERATION_SPEED = 200 # generate at max this many rows per second
const Y_BUFFER = 8#0
const QUANT = 0.1
const DEFAULT_VOLUME = -15

var t = 0
var music_frame = 0
var note_length = 0
var music_level = 0

var binary_rule = ""

var loaded_level = null
var change_history = []

class level_state:
	var data = []
	var rendered = []
	var x_max = 0
	
	func _init(m):
		x_max = m
	
	func has_data(y):
		return data.size() > y
		
	func set_data(x, y, a):
		while data.size() <= y:
			var new_row = []
			for _i in range(x_max):
				new_row.append(0)
			data.append(new_row)
			rendered.append(false)
		
		data[y][x] = a
			
	func get_data(x, y):
		return data[y][x]
			
	func set_rendered(y, value=true):
		if rendered.size() > y:
			rendered[y] = value
	
	func get_rendered(y):
		if rendered.size() > y:
			return rendered[y]
	
func initialize_level():
	clear()
	loaded_level = level_state.new(x_max) 
	$Beep.stop()
	$Boop.stop()
	music_frame = 0
	t = 0
	note_length = 0 
	
	binary_rule = Big.bin(Game.rule)
	
	# first row
	for x in range(0, x_max):
		if Game.initial == Initial.POINT:
			loaded_level.set_data(x, 0, 0)
		elif Game.initial == Initial.RANDOM:
			loaded_level.set_data(x, 0, randi() % 2)
	loaded_level.set_data((x_max-1)/2, 0, 1)
	
	for y in range(1, Game.player.max_depth + Y_BUFFER):
		generate_row(y)
	next_row = Game.player.max_depth + Y_BUFFER
	
func generate_row(y):
	if not loaded_level:
		return
	var neighborhood
	var automaton
	var rule
	
	if Game.story:
		var data = Game.map.get_data(y)
		if not data:
			for x in range(0, x_max):
				loaded_level.set_data(x, y, 2)
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
				loaded_level.get_data((x-1+x_max) % x_max, y-1),
				loaded_level.get_data(x, y-1),
				loaded_level.get_data((x+1) % x_max, y-1)
			]
			
		elif neighborhood == Neighborhood.FIVE_CELL:
			neighbors = [
				loaded_level.get_data((x-2+x_max) % x_max, y-1),
				loaded_level.get_data((x-1+x_max) % x_max, y-1),
				loaded_level.get_data(x, y-1),
				loaded_level.get_data((x+1) % x_max, y-1),
				loaded_level.get_data((x+2) % x_max, y-1),
			]
			
		elif neighborhood == Neighborhood.TWO_STEP:
			if y == 1:
				neighbors = [0, 0, 0,
					loaded_level.get_data((x-1+x_max) % x_max, y-1),
					loaded_level.get_data(x, y-1),
					loaded_level.get_data((x+1) % x_max, y-1),
				]
			else:
				neighbors = [
					loaded_level.get_data((x-1+x_max) % x_max, y-2),
					loaded_level.get_data(x, y-2),
					loaded_level.get_data((x+1) % x_max, y-2),
					loaded_level.get_data((x-1+x_max) % x_max, y-1),
					loaded_level.get_data(x, y-1),
					loaded_level.get_data((x+1) % x_max, y-1),
				]
				
		elif neighborhood == Neighborhood.FIVE_CELL_TWO_STEP:
			if y == 1:
				neighbors = [0, 0, 0, 0, 0,
					loaded_level.get_data((x-2+x_max) % x_max, y-1),
					loaded_level.get_data((x-1+x_max) % x_max, y-1),
					loaded_level.get_data(x, y-1),
					loaded_level.get_data((x+1) % x_max, y-1),
					loaded_level.get_data((x+2) % x_max, y-1),
				]
			else:
				neighbors = [
					loaded_level.get_data((x-2+x_max) % x_max, y-2),
					loaded_level.get_data((x-1+x_max) % x_max, y-2),
					loaded_level.get_data(x, y-2),
					loaded_level.get_data((x+1) % x_max, y-2),
					loaded_level.get_data((x+2) % x_max, y-2),
					loaded_level.get_data((x-2+x_max) % x_max, y-1),
					loaded_level.get_data((x-1+x_max) % x_max, y-1),
					loaded_level.get_data(x, y-1),
					loaded_level.get_data((x+1) % x_max, y-1),
					loaded_level.get_data((x+2) % x_max, y-1),
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
		loaded_level.set_data(x, y, new_cell)

func render_row(y):
	if not loaded_level:
		return
	if not loaded_level.get_rendered(y):
		if loaded_level.has_data(y):
			for x in range(x_max):
				set_cell(x, y, loaded_level.get_data(x, y))
			loaded_level.set_rendered(y)
	
func collided(collision):
	if collision.collider == self:
		var tile_pos = world_to_map(collision.position)
		var tile = get_cellv(tile_pos)
		if tile == 2 and Game.story:
			Game.hit_bottom()

func build(position):
	var x = int(position.x)
	var y = int(position.y) + 1
	if loaded_level.get_data(x, y) != 2:
		loaded_level.set_data(x, y, 1)
		loaded_level.set_rendered(y, false)
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
			if loaded_level.get_data(x, tile_pos.y + d[0]) == 1:
				loaded_level.set_data(x, tile_pos.y + d[0], 0)
			if loaded_level.get_data(x, tile_pos.y - d[0]) == 1:
				loaded_level.set_data(x, tile_pos.y - d[0], 0)
	for y in range(tile_pos.y-5, tile_pos.y+6):
		loaded_level.set_rendered(y, false)
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
	
	# render rows
	var render_min = int(Game.player.position.y) - Y_BUFFER
	var render_max = int(Game.player.position.y) + Y_BUFFER
	for y in range(render_min, render_max):
		render_row(y)
	
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
	
