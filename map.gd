extends Node

const LEVEL_DEPTH = 1550

var map = [
	["CLASSIC", "NEAREST_NEIGHBOR", "82"], # pierinski
	["TOTALISTIC", "FIVE_CELL", "49"], # triangles
	["CLASSIC", "FIVE_CELL_TWO_STEP", "1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034"], # dots and dashes
	["CLASSIC", "TWO_STEP", "7650340787120177667"], # nascar
	["TOTALISTIC", "TWO_STEP", "36"], # hanging gardens
	["CLASSIC", "TWO_STEP", "7255461989027135200"], # cobwebs
	["TOTALISTIC", "TWO_STEP", "9"], # boys boys boys
	["CLASSIC", "FIVE_CELL", "2048938440"], # mossy slope
	["TOTALISTIC", "TWO_STEP", "101"], # circuitboard
	["CLASSIC", "TWO_STEP", "1041049050"], # zigzags
	["TOTALISTIC", "FIVE_CELL_TWO_STEP", "337"], # the mines
	["CLASSIC", "TWO_STEP", "3958639139436560932"], # dicks everywhere
	["TOTALISTIC", "FIVE_CELL_TWO_STEP", "865"], # flesh caves
	["TOTALISTIC", "FIVE_CELL_TWO_STEP", "1712"], # corroded chains
	["TOTALISTIC", "FIVE_CELL_TWO_STEP", "1448"], # ruined caves
	["TOTALISTIC", "TWO_STEP", "105"], # alien skyscrapers
	["CLASSIC", "FIVE_CELL", "716443801"], # pipelines
	["CLASSIC", "FIVE_CELL", "716443750"], # combland
	["CLASSIC", "FIVE_CELL", "3762405914"], # the matrix
	["CLASSIC", "TWO_STEP", "11335363881523069348"], # the ice caves	
	["TOTALISTIC", "FIVE_CELL_TWO_STEP", "225"] # alien den
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
	
