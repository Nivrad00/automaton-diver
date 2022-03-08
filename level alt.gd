extends TileMap

onready var Automaton = Game.Automaton
onready var Neighborhood = Game.Neighborhood
onready var Initial = Game.Initial
onready var x_max = Game.X_MAX
onready var y_max = Game.Y_MAX

var next_row = 0
var start_target = 50 # generate this many rows at the very start
var generation_speed = 160 # generate this many rows per second after starting

const QUANT = 0.1
const DEFAULT_VOLUME = -15

var t = 0
var music_frame = 0
var note_length = 0

var binary_rule = ""

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
	
	# final row
	for x in range(0, x_max):
		set_cell(x, y_max, 2)
		
	for y in range(1, start_target):
		generate_row(y)
	next_row = start_target
	
func generate_row(y):
	for x in range(0, x_max):
		var neighborhood
		
		if Game.neighborhood == Neighborhood.NEAREST_NEIGHBOR:
			neighborhood = [
				get_cell((x-1+x_max) % x_max, y-1),
				get_cell(x, y-1),
				get_cell((x+1) % x_max, y-1)
			]
			
		elif Game.neighborhood == Neighborhood.FIVE_CELL:
			neighborhood = [
				get_cell((x-2+x_max) % x_max, y-1),
				get_cell((x-1+x_max) % x_max, y-1),
				get_cell(x, y-1),
				get_cell((x+1) % x_max, y-1),
				get_cell((x+2) % x_max, y-1),
			]
			
		elif Game.neighborhood == Neighborhood.TWO_STEP:
			if y == 1:
				neighborhood = [0, 0, 0,
					get_cell((x-1+x_max) % x_max, y-1),
					get_cell(x, y-1),
					get_cell((x+1) % x_max, y-1),
				]
			else:
				neighborhood = [
					get_cell((x-1+x_max) % x_max, y-2),
					get_cell(x, y-2),
					get_cell((x+1) % x_max, y-2),
					get_cell((x-1+x_max) % x_max, y-1),
					get_cell(x, y-1),
					get_cell((x+1) % x_max, y-1),
				]
				
		elif Game.neighborhood == Neighborhood.FIVE_CELL_TWO_STEP:
			if y == 1:
				neighborhood = [0, 0, 0, 0, 0,
					get_cell((x-2+x_max) % x_max, y-1),
					get_cell((x-1+x_max) % x_max, y-1),
					get_cell(x, y-1),
					get_cell((x+1) % x_max, y-1),
					get_cell((x+2) % x_max, y-1),
				]
			else:
				neighborhood = [
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
		if Game.automaton == Automaton.CLASSIC:
			for i in range(0, neighborhood.size()):
				bit += neighborhood[i] * pow(2, neighborhood.size() - 1 - i)
				
		elif Game.automaton == Automaton.TOTALISTIC:
			for neighbor in neighborhood:
				bit += neighbor
		
		# choose the cell (based on the corresponding bit of the rule)
		# (rule >> bit) & 1
		var new_cell = int(binary_rule.substr(binary_rule.length()-1-bit, 1))
		set_cell(x, y, new_cell)
			
func collided(collision):
	if collision.collider == self:
		var tile_pos = world_to_map(collision.position)
		var tile = get_cellv(tile_pos)
		if tile == 2:
			Game.next_level()
			
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

func _process(delta):
	t += delta
	
	# generate rows
	var target = min(y_max, int(start_target + t * generation_speed))
	while next_row < target:
		generate_row(next_row)
		next_row += 1
	
	# play music	
	while t > music_frame * QUANT:
		var y = floor(music_frame / x_max) * 10+1
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
	
