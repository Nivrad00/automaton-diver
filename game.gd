extends Node2D

const Big = preload("res://Big.gd")
const X_MAX = 151 # must be odd
const SAVE_FREQ = 1

enum Automaton {CLASSIC, TOTALISTIC}
enum Neighborhood {NEAREST_NEIGHBOR, FIVE_CELL, TWO_STEP, FIVE_CELL_TWO_STEP}
enum Initial {POINT, RANDOM}

var map
var global_time = 0
var last_save = 0

export var story = true

var saw_intro = false
var saw_bottom_cutscene = false
var saw_outro = false
var started = false
var ending = false

var loaded_story = false

var DEFAULT_RULE = {
	Automaton.CLASSIC: {
		Neighborhood.NEAREST_NEIGHBOR: "82",
		Neighborhood.FIVE_CELL: "2048938401",
		Neighborhood.TWO_STEP: "1041049050",
		Neighborhood.FIVE_CELL_TWO_STEP: "1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034"
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

onready var story_level = $StoryLevel
onready var arcade_level = $ArcadeLevel
onready var player = $Player
onready var ui = $UI

func _ready():
	randomize()
	map = load("res://map.gd").new()
	$Loading/Loading.hide()
		
func next_level():
	rule = Big.inc(rule, MAX_RULE[automaton][neighborhood])
	start_level()
	
func start_level():
		
	var save_data
	if story:
		var file = File.new()
		if file.file_exists("user://story_save"):
			file.open("user://story_save", File.READ)
			save_data = file.get_var()
			file.close()
			player.position = save_data["PLAYER_POSITION"]
			player.max_depth = save_data["MAX_DEPTH"]
			saw_intro = save_data["SAW_INTRO"]
			saw_bottom_cutscene = save_data["SAW_BOTTOM_CUTSCENE"]
			saw_outro = save_data["SAW_OUTRO"]
		else:
			player.position = Vector2((X_MAX-1.0)/2.0+0.5, -0.5)
			player.max_depth = player.position.y
			saw_intro = false
			saw_bottom_cutscene = false
			saw_outro = false
	else:
		player.position = Vector2((X_MAX-1.0)/2.0+0.5, -0.5)
		player.max_depth = player.position.y
	
	# prevent player from spawning in the ground
	print(map.LEVEL_DEPTH * map.map.size())
	if player.position.y >= map.LEVEL_DEPTH * map.map.size():
		player.position.y = map.LEVEL_DEPTH * map.map.size() - 1
	
	player.jump_timer = 0
	player.bomb_timer = 0
	player.jumping = false
	player.velocity = Vector2(0, 0)
	
	var zoom = float(X_MAX) / get_viewport_rect().size.x
	$Player/Camera2D.zoom = Vector2(zoom, zoom)
	$Player/Camera2D.limit_left = 0 
	$Player/Camera2D.limit_right = X_MAX
	
	if story:
		if not story_level.visible:
			get_node("Loading/Loading").show()
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
			story_level.show()
			arcade_level.hide()
			story_level.position.x = 0
			arcade_level.position.x = 10000
			get_node("Loading/Loading").hide()	
		if save_data and not loaded_story:
			story_level.redo_changes(save_data["CHANGE_HISTORY"])
			loaded_story = true
		
	else:
		if not arcade_level.visible:
			get_node("Loading/Loading").show()
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
			story_level.hide()
			arcade_level.show()
			story_level.position.x = 10000
			arcade_level.position.x = 0
			get_node("Loading/Loading").hide()
		arcade_level.initialize_level()
	
	
	$UI.set_rule(rule, MAX_RULE[automaton][neighborhood])
	$UI.set_automaton(AUTOMATON_NAME[automaton])
	$UI.set_neighborhood(NEIGHBORHOOD_NAME[neighborhood])
	$UI.set_initial(Initial.keys()[initial])
	
	if story and not saw_intro:
		started = false
		saw_intro = true
		$UI/Intro.show()
	else:
		Game.started = true

func hit_bottom():
	if story and not saw_bottom_cutscene:
		started = false
		saw_bottom_cutscene = true
		$UI/Cutscene.show()

func hit_top():
	if not story or not saw_bottom_cutscene:
		return
	started = false
	ending = true
	
func go_to_rule(new_rule):
	if Big.less_or_equal(new_rule, MAX_RULE[automaton][neighborhood]):
		rule = Big.strip(new_rule)
		start_level()
		return true
	else:
		return false
	
func _input(event):
	if not started:
		return
		
	if not story:
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
		
		if event.is_action_pressed("switch_automaton"):
			automaton = (automaton + 1) % Automaton.size()
			rule = DEFAULT_RULE[automaton][neighborhood]
			start_level()
			
		if event.is_action_pressed("switch_neighborhood"):
			neighborhood = (neighborhood + 1) % Neighborhood.size()
			#if automaton == Automaton.CLASSIC and neighborhood == Neighborhood.FIVE_CELL_TWO_STEP:
				#neighborhood = (neighborhood + 1) % Neighborhood.size()
			rule = DEFAULT_RULE[automaton][neighborhood]
			start_level()
			
		if event.is_action_pressed("switch_initial"):
			initial = (initial + 1) % Initial.size()
			start_level()
		
	if event.is_action_pressed("ui_cancel"):
		$Menu.show_menu()
		Game.started = false
			
	if event.is_action_pressed("mute"):
		AudioServer.set_bus_mute(1, not AudioServer.is_bus_mute(1))
		
func _process(delta):
	if ending:
		player.position.y -= delta * 3.0
		$UI/Black.show()
		$UI/Black.color.a = min(1.0, -player.position.y * 0.05)
		if $UI/Black.color.a == 1.0:
			ending = false
			yield(get_tree().create_timer(1.0), "timeout")
			$UI/Ending.show()
			$UI/Black.hide()
			$UI/Black.color.a == 0.0
			var dir = Directory.new()
			dir.remove("user://story_save")
	
	if not Game.started:
		return
		
	global_time += delta
	if story and global_time - last_save > SAVE_FREQ:
		var file = File.new()
		file.open("user://story_save", File.WRITE)
		file.store_var({
			"PLAYER_POSITION": player.position,
			"MAX_DEPTH": player.max_depth,
			"CHANGE_HISTORY": story_level.change_history,
			"SAW_INTRO": saw_intro,
			"SAW_BOTTOM_CUTSCENE": saw_bottom_cutscene,
			"SAW_OUTRO": saw_outro
		})
		file.close()
		last_save = global_time
		
