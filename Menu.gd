extends CanvasLayer

func _ready():
	show_menu()
	
func start_story():
	Game.story = true
	Game.start_level()
	Game.ui.initialize()
	for child in get_children():
		child.hide()
	Game.started = true

func start_arcade():
	Game.story = false
	Game.start_level()
	Game.ui.initialize()
	for child in get_children():
		child.hide()
	Game.started = true

func show_menu():
	for child in get_children():
		child.show()
	$VBoxContainer/Button2.grab_focus()
