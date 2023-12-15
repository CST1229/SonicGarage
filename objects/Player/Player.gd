extends CharacterBody2D


const SPEED = 6 * 60;
const JUMP_VELOCITY = 6.5 * 60;
const ACCELERATION = 0.046875 * 60 * 60;
const AIR_ACCELERATION = 0.09375 * 60 * 60;
const DECELERATION = 0.5 * 60 * 60;
const FRICTION = 0.046875 * 60 * 60;

const MAX_SPEED_CAP = 24 * 60;

const MIN_ROLL_SPEED = 1 * 60;
const ROLL_FRICTION = 0.0234375 * 60 * 60;
const ROLL_DECELERATION = 0.125 * 60 * 60;
const UNROLL_SPEED = 0.5 * 60;
const MAX_UNROLL_SLOPE_FACTOR = 0.03 * 60 * 60;

const MIN_SLIP_VELOCITY = 2.5 * 60;
const FLOOR_SLIP_ANGLE = deg_to_rad(35);
const FLOOR_FALL_ANGLE = deg_to_rad(70);
const FLOOR_FORCE_FALL_ANGLE = deg_to_rad(90);
const SLIP = 0.5 * 60;

const SLOPE_FACTOR_NORMAL = 0.125 * 60 * 60;
const SLOPE_FACTOR_ROLL_UP = 0.078125 * 60 * 60;
const SLOPE_FACTOR_ROLL_DOWN = 0.3125 * 60 * 60;
const STEEP_SLOPE_FACTOR = 0.05078125 * 60 * 60;

const HITBOX_HEIGHT = 38;
const CROUCHING_HITBOX_HEIGHT = 28;
const HITBOX_WIDTH = 18;
const CROUCHING_HITBOX_WIDTH = 14;

const COYOTE_TIME = 0.1;

const RUN_SPEED = 6 * 60;
const SKID_SPEED = 4 * 60;

var gravity = 0.21875 * 60 * 60;
var falling = 0;
var jumping = false;
var crouching = false;
var rolling = false;
var on_floor = 0;

var controllock_timer = 0;
var jump_buffer = 0;

var spindashing = false;
var spindash_charge = 0.0;
var no_rollcancel = false;

var facing_dir = 1;

var ground_normal = Vector2.UP;
var ground_speed = 0;

@onready var shape: CollisionShape2D = $Shape;
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D;

func _ready():
	set_animation("stand");
	do_layer_color();

func _draw():
	# draw_line(Vector2.ZERO, ground_normal * 32, Color.CYAN, 2, false);
	pass

func _physics_process(delta):
	if is_on_floor():
		falling = 0;

	var direction = Input.get_axis("player_left", "player_right");
	if controllock_timer > 0:
		controllock_timer = move_toward(controllock_timer, 0, delta);
		if falling < 0.1:
			direction = 0;
	if !falling:
		player_control_grounded(direction, delta);
	else:
		if direction:
			if !crouching || rolling:
				facing_dir = direction;
			var accel_mult = 0.25 if (rolling && jumping) else 1.0;
			if sign(velocity.x) == -direction || velocity.x < SPEED:
				velocity.x = move_toward(velocity.x, SPEED * direction, AIR_ACCELERATION * accel_mult * delta);
		if velocity.y > 0 && velocity.y < 4 * 60:
			velocity.x -= floor(velocity.x / 0.125) / 256 * (delta * 60);
		ground_speed = velocity.x;
		
	if jump_buffer > 0:
		jump_buffer = move_toward(jump_buffer, 0, delta);
	if Input.is_action_just_pressed("player_jump"):
		jump_buffer = 0.066;
		
	if jump_buffer > 0 && falling <= COYOTE_TIME && (!crouching || rolling):
		velocity += ground_normal * JUMP_VELOCITY;
		jumping = true;
		jump_buffer = 0;
		falling = 10;
		no_rollcancel = false;
		set_hitbox_height();
	
	var prev_velocity = velocity;
	var prev_floor = is_on_floor();
	
	move_and_slide();
	
	if !falling:
		apply_floor_snap();
	
	# queue_redraw();
	player_react_to_collision(prev_floor, prev_velocity, delta);
	set_hitbox_height();
	
	player_sprites(direction);

func player_control_grounded(direction, delta):
	var ground_angle = -ground_normal.angle_to(Vector2.UP);
	ground_speed = velocity.rotated(-ground_angle).x;
	
	var slope_factor = SLOPE_FACTOR_NORMAL;
	if rolling:
		var moving_up = Vector2(ground_speed, 0).rotated(ground_angle).y < 0;
		if moving_up:
			slope_factor = SLOPE_FACTOR_ROLL_UP;
		else:
			slope_factor = SLOPE_FACTOR_ROLL_DOWN;
	# hack
	elif controllock_timer > 0: slope_factor *= 2;
	slope_factor *= sin(ground_angle);
	
	if rolling && abs(ground_speed) < UNROLL_SPEED && abs(slope_factor) <= MAX_UNROLL_SLOPE_FACTOR:
		crouching = false;
		rolling = false;
		spindashing = false;
	if !crouching && Input.is_action_pressed("player_down"):
		crouching = true;
		if abs(ground_speed) >= MIN_ROLL_SPEED:
			rolling = true;
			no_rollcancel = false;
	if crouching && !rolling && !spindashing && abs(ground_speed) >= MIN_ROLL_SPEED:
		rolling = true;
		no_rollcancel = false;
	
	var started_spindashing = false;
	if crouching && (!rolling || !no_rollcancel) && !spindashing:
		if !Input.is_action_pressed("player_down"):
			crouching = false;
			rolling = false;
		if Input.is_action_just_pressed("player_jump") && !rolling:
			spindashing = true;
			started_spindashing = true;
			spindash_charge = 0.0;
			jump_buffer = 0;
	
	if spindashing:
		if Input.is_action_just_pressed("player_jump") && !started_spindashing:
			sprite.frame = 0;
			sprite.frame_progress = 0;
			spindash_charge = min(10.0, spindash_charge + 2.0);
			jump_buffer = 0;
		spindash_charge -= (floor(spindash_charge / 0.125) / 192.0) * 60 * delta;
		spindash_charge = max(0, spindash_charge);
		if !Input.is_action_pressed("player_down"):
			jump_buffer = 0;
			spindashing = false;
			rolling = true;
			no_rollcancel = true;
			ground_speed = (8.0 + floor(spindash_charge) / 2.0) * 60 * facing_dir;
	
	if direction && !crouching:
		var accel = ACCELERATION * delta;
		if sign(ground_speed) != 0 && sign(ground_speed) == -direction:
			accel = DECELERATION * delta;
		elif velocity.length() > SPEED:
			accel = 0;
		ground_speed = move_toward(ground_speed, SPEED * direction, accel);
	else:
		ground_speed = move_toward(ground_speed, 0, (FRICTION if !rolling else ROLL_FRICTION) * delta);
	
	if rolling && direction == -sign(ground_speed) && ground_speed != 0:
		ground_speed = move_toward(ground_speed, 0, ROLL_DECELERATION * delta);
	
	var debug_speed = 12 if !Input.is_key_pressed(KEY_SHIFT) else 24;
	if Input.is_key_pressed(KEY_0):
		ground_speed = -debug_speed * 60;
	if Input.is_key_pressed(KEY_1):
		ground_speed = debug_speed * 60;
	
	if (abs(ground_normal.angle_to(Vector2.DOWN)) > deg_to_rad(45)):
		if (abs(ground_speed) >= 0 || abs(slope_factor) >= STEEP_SLOPE_FACTOR):
			ground_speed = move_toward(ground_speed, MAX_SPEED_CAP * sign(slope_factor), abs(slope_factor) * delta);
	
	var angle_diff = ground_normal.angle_to(Vector2.UP);
	if ((controllock_timer <= 0 || abs(angle_diff) >= FLOOR_FORCE_FALL_ANGLE) && abs(ground_speed) < MIN_SLIP_VELOCITY && abs(angle_diff) >= FLOOR_SLIP_ANGLE):
		controllock_timer = 0.5;
		crouching = false;
		rolling = false;
		spindashing = false;
		set_hitbox_height();
		if abs(angle_diff) >= FLOOR_FALL_ANGLE:
			up_direction = Vector2.UP;
			ground_normal = Vector2.UP;
			falling = 2;
			velocity.y = 5;
		else:
			if angle_diff > 0:
				ground_speed -= SLIP;
			else:
				ground_speed += SLIP;
	
	if direction != 0 && sign(ground_speed) != -sign(direction) && !crouching:
		facing_dir = direction;
	
	if is_on_wall():
		ground_speed = clamp(ground_speed, -5, 5);
	velocity = Vector2(ground_speed, 0).rotated(ground_angle);

func player_react_to_collision(prev_floor, prev_velocity, delta):
	var hit_floor = is_on_floor();
	if !hit_floor && is_on_ceiling():
		if !test_move(transform, Vector2(-8, -6), null, 0.08, true):
			ground_normal = Vector2.LEFT;
			hit_floor = true;
		elif !test_move(transform, Vector2(8, -6), null, 0.08, true):
			ground_normal = Vector2.RIGHT;
			hit_floor = true;
		if hit_floor:
			prev_floor = false;
	
	if !hit_floor:
		floor_max_angle = deg_to_rad(89);
		on_floor = 0;
		falling += delta;
		velocity.y += gravity * delta;
		
		if falling > COYOTE_TIME:
			ground_normal = Vector2.UP;
		up_direction = Vector2.UP;
		
		if !rolling && !spindashing:
			crouching = false;
		no_rollcancel = false;
		 
		if jumping && !Input.is_action_pressed("player_jump") && velocity.y < -4 * 60:
			velocity.y = -4 * 60;
		if falling > 0.1:
			shape.rotation = 0;
	else:
		floor_max_angle = deg_to_rad(70.0);
		falling = 0;
		jumping = false;
		var old_norm = ground_normal;
		if is_on_floor():
			ground_normal = get_floor_normal();
		if !prev_floor:
			velocity = prev_velocity;
		else:
			velocity = velocity.rotated(old_norm.angle_to(ground_normal));
		up_direction = ground_normal;
		
		const SNAP = deg_to_rad(90);
		shape.rotation = round(-up_direction.angle_to(Vector2.UP) / SNAP) * SNAP;
		on_floor += delta;

func set_hitbox_height():
	var small = crouching || jumping;
	var small_w = rolling || jumping;
	var height = HITBOX_HEIGHT if !small else CROUCHING_HITBOX_HEIGHT;
	var width = HITBOX_WIDTH if !small_w else CROUCHING_HITBOX_WIDTH;
	if shape.shape.size.x != width:
		shape.shape.size.x = width;
	if shape.shape.size.y != height:
		var align = shape.shape.size.y - height;
		var mult = 0.5;
		shape.shape.size.y = height;
		global_position += Vector2(0, align).rotated(shape.global_rotation) * mult;
		if is_on_floor():
			apply_floor_snap();

func set_animation(anim: String):
	sprite.play(anim);

func player_sprites(direction):
	if spindashing:
		set_animation("spindash");
	elif rolling || jumping:
		set_animation("spin");
	elif falling > COYOTE_TIME:
		if crouching:
			set_animation("crouch");
		elif velocity.y < -200:
			set_animation("spring");
		elif abs(ground_speed) >= RUN_SPEED:
			set_animation("run");
		else:
			set_animation("walk");
	else:
		if crouching:
			set_animation("crouch");
		elif direction == facing_dir && is_on_wall():
			set_animation("push");
		elif (abs(ground_speed) > SKID_SPEED || sprite.animation == "skid") && direction == -sign(ground_speed):
			set_animation("skid");
		elif (sprite.animation == "skid" && abs(ground_speed) < 50) || (sprite.animation == "skidturn" && sprite.frame < 1):
			set_animation("skidturn");
		elif abs(ground_speed) >= RUN_SPEED:
			set_animation("run");
		elif direction != 0 || abs(ground_speed) > 5:
			set_animation("walk");
		else:
			set_animation("stand");
	sprite.flip_h = facing_dir == -1;
	if sprite.animation == "spin":
		sprite.rotation = 0;
	else:
		sprite.rotation = -ground_normal.angle_to(Vector2.UP);
	
	if sprite.animation == "walk" || sprite.animation == "run":
		sprite.speed_scale = 1.0 / max(0.016, 8 - abs(ground_speed) / 60);
	elif sprite.animation == "spin":
		sprite.speed_scale = 1.0 / max(0.016, 4 - abs(ground_speed) / 60);
	elif sprite.animation == "push":
		sprite.speed_scale = 1.0 / max(0.016, 8 - abs(ground_speed) / 60 * 4);
	else:
		sprite.speed_scale = 1;
	
	# correct dumb sprite alignment issues
	if sprite.animation != "spin":
		sprite.offset.x = 1 if facing_dir == 1 else 0;
		var should_offset = abs(ground_normal.angle_to(Vector2(-1, -1))) < deg_to_rad(90);
		sprite.offset.y = 1 if should_offset else 0;
	else:
		sprite.offset.x = 0;
		sprite.offset.y = 0;
		if abs(ground_normal.angle_to(Vector2(0, 1))) <= deg_to_rad(45):
			sprite.offset.y = 2;
		elif abs(ground_normal.angle_to(Vector2(1, 0))) <= deg_to_rad(45):
			sprite.offset.x = 1;
		elif abs(ground_normal.angle_to(Vector2(0, -1))) <= deg_to_rad(45):
			sprite.offset.y = 1;
	

func _on_layer_switch(layer: int, grounded_only: bool):
	if grounded_only && falling > 0.1: return;
	collision_layer = layer;
	collision_mask = layer;
	do_layer_color();

func do_layer_color():
	var c = Color.BLACK;
	if collision_layer & (1 << 0):
		c = Color(c.r, c.g + 0.5, c.b + 1);
	if collision_layer & (1 << 1):
		c = Color(c.r + 1, c.g + 0.5, c.b);
	c.a8 = 100;
	shape.debug_color = c;
