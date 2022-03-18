extends ColorRect

func _on_Intro_visibility_changed():
	if visible:
		$Button4.grab_focus()

func _on_Button4_pressed():
	hide()
	Game.started = true
