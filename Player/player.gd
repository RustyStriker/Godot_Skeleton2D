extends KinematicBody2D
class_name PlayerController

# Exporting stuff
export(bool) var spawn_on_floor = true

# Right left movement
const PUSH_DEACC : float = 1000.0 # Pixels / sec
const MAX_SPEED : float = 450.0 # Pixels / sec
const SPEICAL_PUSH_FORCE : float = 600.0

var speed : Vector2 = Vector2() # Pixels / sec
var snare : float = 0.0 # Seconds

# Jump
const GRAVITY : float = 2000.0 # Pixels / sec ^ 2
const JUMP_FORCE : float = 1200.0 # Pixels / sec
const MAX_UP_SPEED : float = 1200.0

const CAYOTE_TIME : float = 0.2 # Seconds
var cayote : float = -1.0

const JUMP_QUEUING : float = 0.2 # Seconds
var queue_jump : float = -1.0 # Seconds

var on_floor : bool = false

func _ready():
	$at.active = true
	# Connections
	if spawn_on_floor:
		spawn_on_floor()

func _process(delta):
	# Jump
	if queue_jump > 0:
		queue_jump -= delta
	if cayote > 0:
		cayote -= delta

func _physics_process(delta):
	# Gathering input
	var input : int = int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left"))
	
	# Apply Input
	speed.x = input * MAX_SPEED
	
	# Apply gravity
	speed.y += GRAVITY * delta
	
	
	var temp_speed = speed
	if temp_speed.y < - MAX_UP_SPEED:
		temp_speed.y = -MAX_UP_SPEED
		speed.y = -MAX_UP_SPEED
	
	# Snare
	if snare > 0:
		snare -= delta
		temp_speed.x = 0
	
	# Move and collide
	var coll = move_and_collide(temp_speed * delta)
	var on_wall : bool = false
	if coll != null:
		# Collision
		if Vector2.UP.dot(coll.normal) > 0.7:
			on_floor = true
		if abs(Vector2.UP.dot(coll.normal)) < 0.7:
			on_wall = true
		var coll2
		if speed.y > GRAVITY * 0.6 and on_floor:
			$at["parameters/land_hard/active"] = true
			speed.x = 0
			snare = 0.3
		elif speed.y > GRAVITY * 0.1 and on_floor:
			$at["parameters/land/active"] = true
		coll2 = move_and_collide(coll.remainder.slide(coll.normal))
		speed = speed.slide(coll.normal)
		if coll2 != null:
			move_and_collide(coll2.remainder.slide(coll2.normal))
			speed = speed.slide(coll2.normal)
			if Vector2.UP.dot(coll2.normal) > 0.7:
				on_floor = true
			if abs(Vector2.UP.dot(coll2.normal)) < 0.7:
				on_wall = true
	# Reseeting the on_floor
	else:
		on_floor = false
	# Flipping
	if speed.x != 0:
		$sprite.scale.x = sign(speed.x) * 0.2
	
	if on_floor:
		# Animations
		if speed == Vector2():
			$at["parameters/state/current"] = 0
		else:
			$at["parameters/state/current"] = 1
		# / Animations
		cayote = CAYOTE_TIME
		if queue_jump >= 0:
			do_jump()
	else: # Not on floor
		# Animations
		if speed.y > 0:
			$at["parameters/state/current"] = 4
		else:
			$at["parameters/state/current"] = 2
		# / Animations
	# Jump
	if Input.is_action_just_pressed("jump"):
		if cayote >= 0:
			do_jump()
		else:
			queue_jump = JUMP_QUEUING

func do_jump():
	speed.y = -JUMP_FORCE
	queue_jump = -1
	cayote = -1
	$at["parameters/jump/active"] = true

func spawn_on_floor():
	var offset = Vector2(0,45)
	var space = get_world_2d().direct_space_state
	var ray = space.intersect_ray(global_position + offset,global_position + Vector2(0,1000),[],1)
	if not ray:
		queue_free()
		printt("ERROR",name,"Could not find floor withing 1000 pixels down")
	elif ray:
		global_position = ray["position"] - offset
