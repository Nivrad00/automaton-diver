extends CanvasLayer

const NUMBER_KEYS = [
	KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9,
	KEY_KP_0, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9
]

func initialize():
	$Panel.hide()
	$RuleInput.hide()
	$InvalidRule.hide()
	$Controls.hide()
	$ShowControls.show()
	
	set_story(Game.story)
		
func set_story(on):
	if on:
		$Controls/Left.hide()
		$Controls/Bottom.hide()
		$Controls/Right/GridContainer/reset.hide()
		$Controls/Right/GridContainer/r.hide()
	else:
		$Controls/Left.show()
		$Controls/Bottom.show()
		$Controls/Right/GridContainer/reset.show()
		$Controls/Right/GridContainer/r.show()
		
	
func _input(event):
	if not Game.story:
		if event is InputEventKey and event.pressed and event.scancode in NUMBER_KEYS:
			$InvalidRule.hide()
			$RuleInput.show()
			if $RuleInput/VBoxContainer/HBoxContainer/Rule.text.length() < 19 or true:
				$RuleInput/VBoxContainer/HBoxContainer/Rule.text += OS.get_scancode_string(event.scancode)

		if event.is_action_pressed("enter"):
			if $RuleInput.visible:
				var new_rule = $RuleInput/VBoxContainer/HBoxContainer/Rule.text
				$RuleInput/VBoxContainer/HBoxContainer/Rule.text = ''
				$RuleInput.hide()
				
				if new_rule != null:
					var success = Game.go_to_rule(new_rule)
					if not success:
						$InvalidRule.show()
						$InvalidRule/Timer.start()
						yield($InvalidRule/Timer, "timeout")
						$InvalidRule.hide()
			
		if event.is_action_pressed("delete"):
			var t = $RuleInput/VBoxContainer/HBoxContainer/Rule.text
			$RuleInput/VBoxContainer/HBoxContainer/Rule.text = t.substr(0, t.length() - 1)
			if $RuleInput/VBoxContainer/HBoxContainer/Rule.text.length() == 0:
				$RuleInput.hide()
			
	if event.is_action_pressed("toggle_controls"):
		if $Controls.visible:
			$Controls.hide()
			$Panel.hide()
			$ShowControls.show()
		else:
			$Controls.show()
			$ShowControls.hide()
			if Game.story:
				$Panel.hide()
				$Controls/Left.hide()
				$Controls/Bottom.hide()
			else:
				$Panel.show()
				$Controls/Left.show()
				$Controls/Bottom.show()
	
func set_rule(a, b):
	$Panel/GridContainer/rule.text = a + "/" + b
	
func set_automaton(a):
	$Panel/GridContainer/automaton.text = a
	
func set_neighborhood(a):
	$Panel/GridContainer/neighborhood.text = a
	
func set_initial(a):
	$Panel/GridContainer/initial_state.text = a

func hide_all():
	for child in get_children():
		child.hide()

func _process(delta):
	if Game.started and not Game.story:
		$Panel/GridContainer/depth.text = str(int(round(Game.player.position.y)))
