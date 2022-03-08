extends CanvasLayer

const NUMBER_KEYS = [
	KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9,
	KEY_KP_0, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9
]

func _ready():
	$RuleInput.hide()
	$InvalidRule.hide()
	$Controls.hide()
	$ShowControls.show()
	
func _input(event):
	if event is InputEventKey and event.pressed and event.scancode in NUMBER_KEYS:
		$InvalidRule.hide()
		$RuleInput.show()
		if $RuleInput/VBoxContainer/HBoxContainer/Rule.text.length() < 19:
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
			$ShowControls.show()
		else:
			$Controls.show()
			$ShowControls.hide()
	
func set_rule(a, b):
	$Panel/GridContainer/rule.text = a + "/" + b
	
func set_automaton(a):
	$Panel/GridContainer/automaton.text = a
	
func set_neighborhood(a):
	$Panel/GridContainer/neighborhood.text = a
	
func set_initial(a):
	$Panel/GridContainer/initial_state.text = a

	
