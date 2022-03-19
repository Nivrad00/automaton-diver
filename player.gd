extends KinematicBody2D

var speed = 17
var jump_speed = -45
var gravity = 180
var max_velocity = 120

var jump_max_time = 0.2
var jump_timer = 0
var jumping = false

var bomb_max_time = 1.2
var bomb_timer = 0
var bombing = false

var velocity = Vector2.ZERO

var max_depth = 0

func _ready():
	$Build.pitch_scale = $Build.stream.get_length() / bomb_max_time
	
func _draw():
	if bombing:
		draw_arc(Vector2(0, 0), (bomb_max_time - bomb_timer) / bomb_max_time * 5.0, 0, 2*PI, 20, Color(1, 1, 1), true)
	else:
		pass
	
func _physics_process(delta):
	if not Game.started:
		return
		
	if position.y <= 0:
		Game.hit_top()
		
	# horizontal movement
	velocity.x = 0
	if Input.is_action_pressed("ui_right"):
		velocity.x += speed
	if Input.is_action_pressed("ui_left"):
		velocity.x -= speed
	if Input.is_action_pressed("slow"):
		velocity.x *= 0.5
	
	# jumping
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		$Bip.play()
		jump_timer = 0
		jumping = true
	
	if jumping:
		velocity.y = jump_speed * (0.8 if Input.is_action_pressed("slow") else 1.0)
		jump_timer += delta
		if Input.is_action_pressed("slow") or\
		not Input.is_action_pressed("ui_up") or\
		jump_timer > jump_max_time:
			jumping = false
	
	# building
	if Input.is_action_just_pressed("jump"):
		$Bip.play()
		if Game.story:
			Game.story_level.build(position)
		else:
			Game.arcade_level.build(position)
	
	# bombing
	if Input.is_action_just_pressed("ui_down"):
		bomb_timer = 0
		bombing = true
		$Build.play()
		print(position.y)
	
	if bombing:
		bomb_timer += delta
		if not Input.is_action_pressed("ui_down"):
			bombing = false
			$Build.stop()
			
		if bomb_timer > bomb_max_time:
			if Game.story:
				Game.story_level.bomb(position)
			else:
				Game.arcade_level.bomb(position)
			$Boom.play()
			bombing = false
	
	# falling and physics
	if bombing:
		velocity = Vector2(0, 0)
	else:
		velocity.y += gravity * delta
		velocity.y = clamp(velocity.y, -max_velocity, max_velocity)
	velocity = move_and_slide(velocity, Vector2.UP)
	
	# interacting with the level
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision and collision.collider == Game.story_level:
			Game.story_level.collided(collision)
		if collision and collision.collider == Game.arcade_level:
			Game.arcade_level.collided(collision)
	
	# screen warp
	while position.x < 0:
		position.x += float(Game.X_MAX)
	while position.x > float(Game.X_MAX):
		position.x -= float(Game.X_MAX)
		
	# drawing
	update()

	max_depth = int(max(max_depth, position.y))
