extends Node

const LEVEL_DEPTH = 1000

var map = [
	["CLASSIC", "NEAREST_NEIGHBOR", "82"],
	["CLASSIC", "TWO_STEP", "1041049050"],
	["TOTALISTIC", "TWO_STEP", "105"],
	["TOTALISTIC", "TWO_STEP", "114"],
	["CLASSIC", "TWO_STEP", "2149670085"],
	["TOTALISTIC", "TWO_STEP", "105"],
	["TOTALISTIC", "FIVE_CELL_TWO_STEP", "1448"],
	["CLASSIC", "FIVE_CELL", "2048938440"],
	["TOTALISTIC", "FIVE_CELL_TWO_STEP", "225"],
	["TOTALISTIC", "TWO_STEP", "36"],
	["TOTALISTIC", "TWO_STEP", "2"],
	["CLASSIC", "FIVE_CELL", "3833641462"],
	["TOTALISTIC", "FIVE_CELL", "52"],
	["CLASSIC", "FIVE_CELL", "8008936"],
	["TOTALISTIC", "FIVE_CELL", "49"],
	["TOTALISTIC", "FIVE_CELL_TWO_STEP", "1959"]
]

func _init():
	for key in map:
		key[0] = Game.Automaton[key[0]]
		key[1] = Game.Neighborhood[key[1]]
		key[2] = Big.bin(key[2])
	
func get_data(y):
	var level = floor(y / LEVEL_DEPTH)
	if level >= map.size():
		return null
	return map[level]
	
