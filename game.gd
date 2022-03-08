extends Node2D

const Big = preload("res://Big.gd")
const X_MAX = 151 # must be odd
const Y_MAX = 1000

enum Automaton {CLASSIC, TOTALISTIC}
enum Neighborhood {NEAREST_NEIGHBOR, FIVE_CELL, TWO_STEP, FIVE_CELL_TWO_STEP}
enum Initial {POINT, RANDOM}

var DEFAULT_RULE = {
	Automaton.CLASSIC: {
		Neighborhood.NEAREST_NEIGHBOR: "82",
		Neighborhood.FIVE_CELL: "2048938401",
		Neighborhood.TWO_STEP: "1041049050",
		Neighborhood.FIVE_CELL_TWO_STEP: "0"
	}, 
	Automaton.TOTALISTIC: {
		Neighborhood.NEAREST_NEIGHBOR: "5",
		Neighborhood.FIVE_CELL: "49",
		Neighborhood.TWO_STEP: "105",
		Neighborhood.FIVE_CELL_TWO_STEP: "1959"
	}
}
var MAX_RULE = {
	Automaton.CLASSIC: {
		Neighborhood.NEAREST_NEIGHBOR: "255",
		Neighborhood.FIVE_CELL: "4294967295",
		Neighborhood.TWO_STEP: "18446744073709551615",
		Neighborhood.FIVE_CELL_TWO_STEP: "179769313486231590772930519078902473361797697894230657273430081157732675805500963132708477322407536021120113879871393357658789768814416622492847430639474124377767893424865485276302219601246094119453082952085005768838150682342462881473913110540827237163350510684586298239947245938479716304835356329624224137215"
	}, 
	Automaton.TOTALISTIC: {
		Neighborhood.NEAREST_NEIGHBOR: "16",
		Neighborhood.FIVE_CELL: "63",
		Neighborhood.TWO_STEP: "127",
		Neighborhood.FIVE_CELL_TWO_STEP: "2047"
	}
}
const NEIGHBORHOOD_NAME = {
	Neighborhood.NEAREST_NEIGHBOR: "Nearest Neighbor",
	Neighborhood.FIVE_CELL: "5-Cell",
	Neighborhood.TWO_STEP: "2-Steps-Back",
	Neighborhood.FIVE_CELL_TWO_STEP: "5-Cell 2-Steps-Back"
}
const AUTOMATON_NAME = {
	Automaton.CLASSIC: "Classic",
	Automaton.TOTALISTIC: "Totalistic"
}

var automaton = Automaton.CLASSIC
var neighborhood = Neighborhood.NEAREST_NEIGHBOR
var initial = Initial.POINT
var rule = "82"

onready var level = $Level
onready var player = $Player

func _ready():
	randomize()
	start_level()

func next_level():
	rule = Big.inc(rule, MAX_RULE[automaton][neighborhood])
	start_level()
	
func start_level():
	$Level.initialize_level()
	
	$Player.position = Vector2((X_MAX-1.0)/2.0+0.5, -0.5)
	$Player.jump_timer = 0
	$Player.bomb_timer = 0
	$Player.jumping = false
	$Player.velocity = Vector2(0, 0)
	var zoom = float(X_MAX) / get_viewport_rect().size.x
	$Player/Camera2D.zoom = Vector2(zoom, zoom)
	
	$UI.set_rule(rule, MAX_RULE[automaton][neighborhood])
	$UI.set_automaton(AUTOMATON_NAME[automaton])
	$UI.set_neighborhood(NEIGHBORHOOD_NAME[neighborhood])
	$UI.set_initial(Initial.keys()[initial])
	
func go_to_rule(new_rule):
	if Big.less_or_equal(new_rule, MAX_RULE[automaton][neighborhood]):
		rule = Big.strip(new_rule)
		start_level()
		return true
	else:
		return false
		
func _input(event):
	if event.is_action_pressed("next"):
		next_level()
	if event.is_action_pressed("previous"):
		rule = Big.dec(rule, MAX_RULE[automaton][neighborhood])
		start_level()
	
	if event.is_action_pressed("random"):
		rule = Big.rand(MAX_RULE[automaton][neighborhood])
		start_level()
	
	if event.is_action_pressed("reset"):
		start_level()
		
	if event.is_action_pressed("mute"):
		AudioServer.set_bus_mute(1, not AudioServer.is_bus_mute(1))
		
	if event.is_action_pressed("switch_automaton"):
		automaton = (automaton + 1) % Automaton.size()
		rule = DEFAULT_RULE[automaton][neighborhood]
		start_level()
		
	if event.is_action_pressed("switch_neighborhood"):
		neighborhood = (neighborhood + 1) % Neighborhood.size()
		if automaton == Automaton.CLASSIC and neighborhood == Neighborhood.FIVE_CELL_TWO_STEP:
			neighborhood = (neighborhood + 1) % Neighborhood.size()
		rule = DEFAULT_RULE[automaton][neighborhood]
		start_level()
		
	if event.is_action_pressed("switch_initial"):
		initial = (initial + 1) % Initial.size()
		start_level()
		
	
