extends TileMap

onready var Automaton = Game.Automaton
onready var Initial = Game.Initial
onready var x_max = Game.X_MAX
onready var y_max = Game.Y_MAX

var next_row = 0
var start_target = 50 # generate this many rows at the very start
var generation_speed = 160 # generate this many rows per second after starting

const QUANT = 0.1
const EAR_HURT_LENGTH = 0.4
const DEFAULT_VOLUME = -15

var t = 0
var music_frame = 0
var note_length = 0

func initialize_level():
	clear()
	$Beep.stop()
	$Boop.stop()
	music_frame = 0
	t = 0
	note_length = 0 
	
	for x in range(0, x_max):
		if Game.initial == Initial.POINT:
			set_cell(x, 0, 0)
		elif Game.initial == Initial.RANDOM:
			set_cell(x, 0, randi() % 2)
	set_cell((x_max-1)/2, 0, 1)
	for y in range(1, start_target):
		generate_row(y)
	next_row = start_target
	
func generate_row(y):
	for x in range(0, x_max):
		var neighborhood
		
		if Game.automaton in [Automaton.ELEMENTARY]:
			neighborhood = [
				get_cell((x-1+x_max) % x_max, y-1),
				get_cell(x, y-1),
				get_cell((x+1) % x_max, y-1)
			]
			
		elif Game.automaton in [Automaton.FIVE_CELL_ELEM, Automaton.FIVE_CELL]:
			neighborhood = [
				get_cell((x-2+x_max) % x_max, y-1),
				get_cell((x-1+x_max) % x_max, y-1),
				get_cell(x, y-1),
				get_cell((x+1) % x_max, y-1),
				get_cell((x+2) % x_max, y-1),
			]
			
		elif Game.automaton == Automaton.TWO_STEP:
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
				
		elif Game.automaton == Automaton.FIVE_CELL_TWO_STEP:
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
		if Game.automaton == Automaton.ELEMENTARY:
			bit = neighborhood[0]*4 + neighborhood[1]*2 + neighborhood[2]
		
		elif Game.automaton == Automaton.FIVE_CELL_ELEM:
			bit = neighborhood[0]*16 + neighborhood[1]*8 + neighborhood[2]*4 + neighborhood[3]*2 + neighborhood[4]
			
		elif Game.automaton in [Automaton.FIVE_CELL, Automaton.TWO_STEP, Automaton.FIVE_CELL_TWO_STEP]:
			for neighbor in neighborhood:
				bit += neighbor
		
		# choose the cell (based on the corresponding bit of the rule)
		var new_cell = (Game.rule >> bit) & 1
		set_cell(x, y, new_cell)
	
	# generate final row
	#for x in range(0, x_max):
		#set_cell(x, y_max-1, 2)
			
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
		var y = floor(music_frame / x_max)
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
			note_length = 0
		else:
			var pitch = pow(2, music1 / 15.5) * 0.8
			if stepify(pitch, 0.01) != stepify($Beep.pitch_scale, 0.01):
				$Beep.pitch_scale = pitch
				note_length = 0
			if not $Beep.playing:
				$Beep.play()
				
		if music2 == 0:
			$Boop.stop()
			note_length = 0
		else:
			var pitch = pow(2, music2 / 15.5 - 2) * 0.8
			if stepify(pitch, 0.01) != stepify($Boop.pitch_scale, 0.01):
				$Boop.pitch_scale = pitch
				note_length = 0
			if not $Boop.playing:
				$Boop.play()
		music_frame += 1
	
	if $Beep.playing or $Boop.playing:
		note_length += delta
		
	if note_length >= EAR_HURT_LENGTH:
		$Beep.volume_db = DEFAULT_VOLUME - clamp(note_length - EAR_HURT_LENGTH, 0, 5) * 2
		$Boop.volume_db = DEFAULT_VOLUME - clamp(note_length - EAR_HURT_LENGTH, 0, 5) * 2 + 1
	else:
		$Beep.volume_db = DEFAULT_VOLUME
		$Boop.volume_db = DEFAULT_VOLUME + 1
	
