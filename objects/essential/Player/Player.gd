## The player.
##
## HUGE thanks to the Sonic Physics Guide!!
## https://info.sonicretro.org/Sonic_Physics_Guide
extends CharacterBody2D
class_name Player

## If true, enables stuff like instant speed boosts.
@export var DEBUG_MODE: bool = OS.has_feature("editor");
## fun debug stuff
const DEBUG_ALWAYSJUMP = false;

enum State {
	## Normal gameplay.
	NORMAL,
	## Level completion state.
	LEVEL_COMPLETE,
	## Hurt state.
	HURT,
	## Death state.
	DEAD,
	## Debug fly state.
	DEBUG,
}
var state := State.NORMAL;
var queue_level_complete := false;

# normal running constants
const SPEED = 6 * 60;
const JUMP_VELOCITY = 6.5 * 60;
const ACCELERATION = 0.046875 * 60 * 60;
const AIR_ACCELERATION = 0.09375 * 60 * 60;
const DECELERATION = 0.5 * 60 * 60;
const FRICTION = 0.046875 * 60 * 60;

const MAX_SPEED_CAP = 24 * 60;

# rolling constants
const MIN_ROLL_SPEED = 1 * 60;
const ROLL_FRICTION = 0.0234375 * 60 * 60;
const ROLL_DECELERATION = 0.125 * 60 * 60;
const UNROLL_SPEED = 0.5 * 60;
const MAX_UNROLL_SLOPE_FACTOR = 0.03 * 60 * 60;

# slipping constants
const MIN_SLIP_VELOCITY = 2.5 * 60;
const FLOOR_SLIP_ANGLE = deg_to_rad(35);
const FLOOR_FALL_ANGLE = deg_to_rad(70);
const FLOOR_FORCE_FALL_ANGLE = deg_to_rad(90);
const SLIP = 0.5 * 60;

# slope constants
const SLOPE_FACTOR_NORMAL = 0.125 * 60 * 60;
const SLOPE_FACTOR_ROLL_UP = 0.078125 * 60 * 60;
const SLOPE_FACTOR_ROLL_DOWN = 0.3125 * 60 * 60;
const STEEP_SLOPE_FACTOR = 0.05078125 * 60 * 60;

# hitbox constants
const HITBOX_HEIGHT = 38;
const CROUCHING_HITBOX_HEIGHT = 28;
const HITBOX_WIDTH = 18;
const CROUCHING_HITBOX_WIDTH = 14;

# anti-frustration constants
# aka, being able to buffer jumps in both directions
const COYOTE_TIME = 0.1;
const JUMP_BUFFER_TIME = 0.066;

const RUN_SPEED = 6 * 60;
const SKID_SPEED = 4 * 60;

# hurt/death constants
const HURT_SPEED_X = -2.0 * 60;
const HURT_SPEED_Y = -4.0 * 60;
const HURT_GRAVITY = 0.1875 * 60 * 60;
const DEAD_SPEED_Y = -7 * 60;

const AIR_FLOOR_MAX_ANGLE = deg_to_rad(70);
const AIR_FLOOR_MAX_ANGLE_DOWN = deg_to_rad(85);
const GROUND_FLOOR_MAX_ANGLE =  deg_to_rad(65);

# the variables, i don't feel like
# categorizing them
var gravity := 0.21875 * 60 * 60;
var falling := 100.0;
var jumping := false;
var crouching := false;
var rolling := false;
var on_floor := 0.0;
var springing := false;
var just_sprung := 0;

var controllock_timer := 0.0;
var jump_buffer := 0.0;
# "multi-bind-press" input proxies
var jump_pressed := false;

var spindashing := false;
var spindash_charge := 0.0;
var no_rollcancel := false;

var facing_dir := 1.0;
var hurt_direction := 1.0;

var ground_normal := Vector2.UP;
var ground_speed := 0.0;

var on_wall := 0.0;
var wall_dir: int = 0;

var terrain_layer: int = LevelUtil.LAYER_A | LevelUtil.LAYER_B;

var invulnerable := 0.0;
var dead_timer := 0.0;

var debug_velocity := 0.0;

@onready var shape: CollisionShape2D = $Shape;
@onready var sprite: AnimatedSprite2D = $sprite;
@onready var camera: Camera2D = $Camera;

@onready var jump_sound: AudioStreamPlayer = $jump_sound;
@onready var roll_sound: AudioStreamPlayer = $roll_sound;
@onready var skid_sound: AudioStreamPlayer = $skid_sound;
@onready var dash_sound: AudioStreamPlayer = $dash_sound;
@onready var hurt_sound: AudioStreamPlayer = $hurt_sound;
@onready var ringloss_sound: AudioStreamPlayer = $ringloss_sound;

@onready var ceiling_normal_raycast: RayCast2D = $Shape/CeilingNormal;
@onready var ceiling_normal_raycast_2: RayCast2D = $Shape/CeilingNormal2;

@onready var debug_labels: CanvasLayer = $DebugLabels;
@onready var debug_label: Label = $DebugLabels/DebugLabel;
@onready var old_debug_label_text := debug_label.text;

func _ready():
	apply_floor_snap();
	set_animation("stand");
	update_layer();
	do_layer_color();
	set_hitbox_height();
	debug_labels.visible = DEBUG_MODE; 
	

func _draw():
	# the debug line(tm)
	if DEBUG_MODE:
		draw_line(Vector2.ZERO, ground_normal * 32, Color.CYAN, 2, false);
		draw_line(Vector2.ZERO, velocity / 15.0, Color.MEDIUM_AQUAMARINE, 2, false);
		
		debug_label.text = old_debug_label_text % [
			position.x, position.y,
			velocity.x / 60, velocity.y / 60,
			ground_speed / 60
		];
# pad a leading minus in a number
func pad_minus(num: float):
	num = snappedf(num, 0.00001);
	if num >= 0.0:
		return " " + str(num);
	return str(num);


func _physics_process(delta: float):
	# inputs
	if jump_buffer > 0:
		jump_buffer = move_toward(jump_buffer, 0, delta);
	if DEBUG_ALWAYSJUMP:
		jump_pressed = true
	if jump_pressed:
		jump_buffer = JUMP_BUFFER_TIME;
	
	if (state == State.NORMAL || state == State.HURT) && invulnerable > 0:
		invulnerable = move_toward(invulnerable, 0, delta);
		
		var flash_time = 1.0 / 15.0;
		var flash := fmod(invulnerable, flash_time);
		sprite.visible = flash > (flash_time / 2);
	else:
		invulnerable = 0;
		sprite.visible = true;
	
	if queue_level_complete && is_on_floor():
		velocity.x = 0;
		if velocity.y < 0: velocity.y = 0;
		state = State.LEVEL_COMPLETE;
		queue_level_complete = false;
	
	if Input.is_action_just_pressed("debug") && DEBUG_MODE:
		if state == State.DEBUG:
			state = State.NORMAL;
			debug_velocity = 0;
			shape.disabled = false;
		else:
			state = State.DEBUG;
			debug_velocity = 0;
			shape.disabled = true;
		
	match state:
		State.NORMAL:
			tick_normal(delta);
			update_layer();
		State.LEVEL_COMPLETE:
			tick_levelcomplete(delta);
		State.HURT:
			tick_hurt(delta);
		State.DEAD:
			tick_dead(delta);
		State.DEBUG:
			tick_debug(delta);
	
	if just_sprung > 0:
		just_sprung -= 1;
	jump_pressed = false;
	
	if DEBUG_MODE:
		queue_redraw();

func tick_normal(delta: float):
	var direction: float = signf(Input.get_axis("player_left", "player_right"));
	if controllock_timer > 0:
		controllock_timer = move_toward(controllock_timer, 0, delta);
		if falling < 0.1:
			direction = 0;
	
	if !falling:
		player_control_grounded(direction, delta);
	else:
		player_control_falling(direction, delta);
	
	if jump_buffer > 0 && falling <= COYOTE_TIME && (!crouching || rolling):
		velocity += ground_normal * JUMP_VELOCITY;
		emit_sudden_momentum_change();
		jumping = true;
		jump_buffer = 0;
		falling = 100;
		no_rollcancel = false;
		jump_sound.play();
		set_hitbox_height();
	
	# move!
	var prev_velocity: Vector2 = velocity;
	var prev_floor: bool = is_on_floor();
	move_and_slide();
	if !falling:
		apply_floor_snap();
	
	if is_on_wall():
		on_wall = 0.1;
		if get_wall_normal().x > 0:
			wall_dir = -1;
		else:
			wall_dir = 1;
	else:
		on_wall = move_toward(on_wall, 0, delta);
	
	player_react_to_collision(prev_floor, prev_velocity, delta);
	set_hitbox_height();
	
	var collision: KinematicCollision2D = get_last_slide_collision();
	if collision && collision.get_collider() is Touchbox:
		collision.get_collider().touched.emit(self);
	
	player_sprites(direction);

func player_control_grounded(direction: float, delta: float):
	var ground_angle: float = -ground_normal.angle_to(Vector2.UP);
	ground_speed = velocity.rotated(-ground_angle).x;
	
	# sliding on slopes
	var slope_factor := SLOPE_FACTOR_NORMAL;
	if rolling:
		var moving_up = Vector2(ground_speed, 0).rotated(ground_angle).y < 0;
		if moving_up:
			slope_factor = SLOPE_FACTOR_ROLL_UP;
		else:
			slope_factor = SLOPE_FACTOR_ROLL_DOWN;
	# hack to make slipping smoother
	elif controllock_timer > 0: slope_factor *= 2;
	slope_factor *= sin(ground_angle);
	
	# rolling
	if rolling && absf(ground_speed) < UNROLL_SPEED && absf(slope_factor) <= MAX_UNROLL_SLOPE_FACTOR:
		crouching = false;
		rolling = false;
		spindashing = false;
	if !crouching && Input.is_action_pressed("player_down"):
		crouching = true;
		if absf(ground_speed) >= MIN_ROLL_SPEED:
			rolling = true;
			no_rollcancel = false;
			roll_sound.play();
	if crouching && !rolling && !spindashing && absf(ground_speed) >= MIN_ROLL_SPEED:
		rolling = true;
		no_rollcancel = false;
		roll_sound.play();
	
	# crouching
	var started_spindashing := false;
	if crouching && (!rolling || !no_rollcancel) && !spindashing:
		if !Input.is_action_pressed("player_down"):
			crouching = false;
			rolling = false;
			roll_sound.stop();
		if jump_buffer > 0 && crouching && !rolling && !spindashing:
			spindashing = true;
			started_spindashing = true;
			spindash_charge = 0.0;
			jump_buffer = 0;
			GlobalSounds.stop_spindash();
			GlobalSounds.play_spindash();
	
	# spindashing
	if spindashing:
		if jump_pressed && !started_spindashing:
			# charge
			sprite.frame = 0;
			sprite.frame_progress = 0;
			spindash_charge = min(10.0, spindash_charge + 2.0);
			jump_buffer = 0;
			GlobalSounds.play_spindash();
		spindash_charge -= (floorf(spindash_charge / 0.125) / 192.0) * 60 * delta;
		spindash_charge = max(0, spindash_charge);
		if !Input.is_action_pressed("player_down"):
			# release
			jump_buffer = 0;
			spindashing = false;
			rolling = true;
			no_rollcancel = true;
			GlobalSounds.stop_spindash();
			dash_sound.play();
			ground_speed = (8.0 + floorf(spindash_charge) / 2.0) * 60 * facing_dir;
	
	# acceleration and deceleration
	if direction && !crouching:
		var accel = ACCELERATION * delta;
		if signf(ground_speed) != 0 && signf(ground_speed) == -direction:
			accel = DECELERATION * delta;
		elif velocity.length() > SPEED:
			accel = 0;
		ground_speed = move_toward(ground_speed, SPEED * direction, accel);
	else:
		ground_speed = move_toward(ground_speed, 0, (FRICTION if !rolling else ROLL_FRICTION) * delta);
	if rolling && direction == -signf(ground_speed) && ground_speed != 0:
		ground_speed = move_toward(ground_speed, 0, ROLL_DECELERATION * delta);
	
	# debug instant speed keybinds
	if DEBUG_MODE:
		var debug_speed = 12 if !Input.is_key_pressed(KEY_SHIFT) else 24;
		if Input.is_key_pressed(KEY_0):
			ground_speed = -debug_speed * 60;
		if Input.is_key_pressed(KEY_1):
			ground_speed = debug_speed * 60;
	
	# actually apply the slope factor
	if (absf(ground_normal.angle_to(Vector2.DOWN)) > deg_to_rad(45)):
		if (absf(ground_speed) >= 0 || absf(slope_factor) >= STEEP_SLOPE_FACTOR):
			ground_speed = move_toward(ground_speed, MAX_SPEED_CAP * signf(slope_factor), absf(slope_factor) * delta);
	
	# slipping and falling on slopes
	var angle_diff = ground_normal.angle_to(Vector2.UP);
	if ((controllock_timer <= 0 || absf(angle_diff) >= FLOOR_FORCE_FALL_ANGLE) && absf(ground_speed) < MIN_SLIP_VELOCITY && absf(angle_diff) >= FLOOR_SLIP_ANGLE):
		controllock_timer = 0.5;
		crouching = false;
		rolling = false;
		spindashing = false;
		set_hitbox_height();
		if absf(angle_diff) >= FLOOR_FALL_ANGLE:
			up_direction = Vector2.UP;
			ground_normal = Vector2.UP;
			falling = 2;
			velocity.y = 5;
		else:
			if angle_diff > 0:
				ground_speed -= SLIP;
			else:
				ground_speed += SLIP;
	elif controllock_timer > 0 && absf(angle_diff) < FLOOR_SLIP_ANGLE:
		controllock_timer = 0;
	
	if direction != 0 && signf(ground_speed) != -signf(direction) && !crouching:
		facing_dir = direction;
	
	# apply the ground speed
	velocity = Vector2(ground_speed, 0).rotated(ground_angle);

func player_control_falling(direction: float, delta: float):
	no_rollcancel = false;
	if direction:
		if !crouching || rolling:
			facing_dir = direction;
		# acceleration, deceleration
		# a lot simpler than when grounded
		var accel_mult := 0.25 if (rolling && jumping) else 1.0;
		if signf(velocity.x) == -direction || absf(velocity.x) < SPEED:
			velocity.x = move_toward(velocity.x, SPEED * direction, AIR_ACCELERATION * accel_mult * delta);
	
	# air drag
	if velocity.y > 0 && velocity.y < 4 * 60:
		velocity.x -= floorf(velocity.x / 0.125) / 256.0 * (delta * 60);
	
	ground_speed = velocity.x;

func player_react_to_collision(prev_floor: bool, prev_velocity: Vector2, delta: float):
	# ceiling collisions
	var hit_floor = is_on_floor();
	ceiling_normal_raycast.force_raycast_update();
	ceiling_normal_raycast_2.force_raycast_update();
	if !hit_floor && is_on_ceiling() && (ceiling_normal_raycast.is_colliding() \
		|| ceiling_normal_raycast_2.is_colliding()):
		# get_ceiling_normal doesnt exist aaaaa
		var ceiling_normal := Vector2.ZERO;
		if (ceiling_normal_raycast.is_colliding() && ceiling_normal_raycast_2.is_colliding()):
			ceiling_normal = Vector2.from_angle(
				lerp_angle(
					ceiling_normal_raycast.get_collision_normal().angle(),
					ceiling_normal_raycast_2.get_collision_normal().angle(),
					0.5
				)
			);
		elif ceiling_normal_raycast.is_colliding():
			ceiling_normal = ceiling_normal_raycast.get_collision_normal();
		else:
			ceiling_normal = ceiling_normal_raycast_2.get_collision_normal();
		if absf(ceiling_normal.x) < 0.95 && absf(ceiling_normal.x) > 0.8:
			if ceiling_normal.x < 0:
				ground_normal = Vector2.LEFT;
				hit_floor = true;
			else:
				ground_normal = Vector2.RIGHT;
				hit_floor = true;
		if hit_floor:
			prev_floor = false;
	
	if !hit_floor:
		on_floor = 0;
		falling += delta;
		velocity.y += gravity * delta;
		if velocity.y > 0:
			floor_max_angle = AIR_FLOOR_MAX_ANGLE_DOWN;
		else:
			floor_max_angle = AIR_FLOOR_MAX_ANGLE;
		
		if falling > COYOTE_TIME:
			ground_normal = Vector2.UP;
		up_direction = Vector2.UP;
		
		if !rolling && !spindashing:
			crouching = false;
		no_rollcancel = false;
		 
		# jump stop
		if jumping && !Input.is_action_pressed("player_jump") && velocity.y < -4 * 60:
			velocity.y = -4 * 60;
		if falling > 0.1:
			shape.rotation = 0;
	else:
		floor_max_angle = GROUND_FLOOR_MAX_ANGLE;
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
		
		if !prev_floor && rolling && Input.is_action_pressed("player_down") && absf(velocity.length()) >= MIN_ROLL_SPEED:
			roll_sound.play();
		
		const SNAP = deg_to_rad(45);
		shape.rotation = snappedf(-up_direction.angle_to(Vector2.UP), SNAP);
		# shape.rotation = -up_direction.angle_to(Vector2.UP);
		on_floor += delta;
	if is_on_floor():
		falling = 0;

func set_hitbox_height():
	# in the classic games, crouching makes your hitbox thinner too
	# but i think that's a bit weird and also causes weirdness when
	# crouching near a ledge
	
	var small := crouching || jumping;
	var small_w := rolling || jumping;
	var height := HITBOX_HEIGHT if !small else CROUCHING_HITBOX_HEIGHT;
	var width := HITBOX_WIDTH if !small_w else CROUCHING_HITBOX_WIDTH;
	
	shape.shape.size.x = width;
	ceiling_normal_raycast.position.x = width / 2.0;
	ceiling_normal_raycast_2.position.x = width / -2.0;
	shape.shape.size.y = height;
	ceiling_normal_raycast.target_position = Vector2(
		0, -height / 2.0 - 24.0
	);
	ceiling_normal_raycast_2.target_position = ceiling_normal_raycast.target_position;
	shape.position.y = (HITBOX_HEIGHT - height) / 2.0;

func tick_levelcomplete(delta: float):
	if sprite.animation != "levelcomplete_loop":
		set_animation("levelcomplete");
		if sprite.frame >= 2:
			set_animation("levelcomplete_loop");
	velocity.y += gravity * delta;
	
	floor_stop_on_slope = true;
	floor_max_angle = GROUND_FLOOR_MAX_ANGLE;
	up_direction = Vector2.UP;
	ground_normal = Vector2.UP;
	
	crouching = false;
	rolling = false;
	jumping = false;
	set_hitbox_height();
	
	shape.rotation = 0;
	sprite.rotation = 0;
	sprite.speed_scale = 1;
	
	move_and_slide();

func tick_hurt(delta: float):
	up_direction = Vector2.UP;
	ground_normal = Vector2.UP;
	rolling = false;
	jumping = false;
	spindashing = false;
	falling = 1000;
	on_floor = 0;
	on_wall = 0;
	if velocity.y > 0:
		floor_max_angle = AIR_FLOOR_MAX_ANGLE_DOWN;
	else:
		floor_max_angle = AIR_FLOOR_MAX_ANGLE;
	
	shape.rotation = 0;
	sprite.rotation = 0;
	sprite.speed_scale = 1;
	
	controllock_timer = 0;
	
	velocity.x = HURT_SPEED_X * hurt_direction;
	set_animation("hurt");
	
	move_and_slide();
	
	invulnerable = 0;
	if is_on_floor():
		set_animation("stand");
		velocity.x = 0;
		state = State.NORMAL;
		falling = 0;
		invulnerable = 2;
	
	velocity.y += HURT_GRAVITY * delta;

func tick_dead(delta: float):
	set_animation("dead");
	velocity.y += HURT_GRAVITY * delta;
	invulnerable = 0;
	
	position.y += velocity.y * delta;
	
	collision_layer = 0;
	collision_mask = 0;
	
	shape.rotation = 0;
	sprite.rotation = 0;
	sprite.speed_scale = 1;
	
	dead_timer = move_toward(dead_timer, 0, delta);
	if dead_timer <= 0:
		var scene = Fades.current_scene as EditorRoomBase;
		if scene.has_method("playtest") && scene.has_method("exit"):
			if scene.playtest_room:
				scene.playtest();
			else:
				scene.exit();

func tick_debug(delta: float) -> void:
	const DEBUG_MIN_VELOCITY := 5.0 * 60;
	const DEBUG_ACCELERATION := 0.1 * 60 * 60;
	var vec := Input.get_vector(
		"player_left", "player_right", "player_up", "player_down"
	);
	if vec == Vector2.ZERO:
		if (
			!Input.is_action_pressed("player_up") &&
			!Input.is_action_pressed("player_down") &&
			!Input.is_action_pressed("player_left") &&
			!Input.is_action_pressed("player_right")
		):
			debug_velocity = 0;
		elif (
			Input.is_action_pressed("player_up") &&
			Input.is_action_pressed("player_down") &&
			Input.is_action_pressed("player_left") &&
			Input.is_action_pressed("player_right")
		):
			debug_velocity += DEBUG_ACCELERATION * delta;
	else:
		debug_velocity += DEBUG_ACCELERATION * delta;
	
	var actual_velocity := 0.0;
	if vec == Vector2.ZERO:
		actual_velocity = 0;
	elif Input.is_action_pressed("player_jump"):
		actual_velocity = DEBUG_MIN_VELOCITY + debug_velocity * 2.0;
	else:
		actual_velocity = DEBUG_MIN_VELOCITY + debug_velocity;
	
	velocity = vec * actual_velocity;
	position += velocity * delta;
	
	sprite.rotation = 0;
	ground_normal = Vector2.UP;
	if vec.x != 0:
		facing_dir = signf(vec.x);
	crouching = false;
	rolling = false;
	spindashing = false;
	jumping = false;
	springing = false;
	no_rollcancel = false;
	falling = 999;
	
	sprite.play("stand");
	sprite.flip_h = facing_dir == -1.0;

func hurt(direction := 0) -> bool:
	if state != State.NORMAL || invulnerable > 0:
		return false;
	
	emit_sudden_momentum_change();
	
	if LevelUtil.level_manager && LevelUtil.level_manager.rings <= 0:
		kill();
		return true;
	
	hurt_sound.play();
	
	if LevelUtil.level_manager.rings > 0:
		ringloss_sound.play();
		scatter_rings(LevelUtil.level_manager.rings);
	LevelUtil.level_manager.rings = 0;
	
	state = State.HURT;
	velocity.y = HURT_SPEED_Y;
	if direction == 0:
		hurt_direction = facing_dir;
	else:
		hurt_direction = direction;
	velocity.x = HURT_SPEED_X * hurt_direction;
	set_animation("hurt");
	return true;

# https://info.sonicretro.org/SPG:Ring_Loss#Ring_Distribution
var SCATTERED_RING = load("res://objects/level/Ring/ScatteredRing.tscn");
func scatter_rings(rings: int):
	rings = min(rings, 32);
	
	const RING_STARTING_ANGLE = deg_to_rad(101.25);
	
	var ring_angle := RING_STARTING_ANGLE; 
	var ring_flip := false;
	var ring_speed := 4.0 * 60.0;
	var add_angle := deg_to_rad(22.5);
	var cycle_angle := RING_STARTING_ANGLE + deg_to_rad(90);
	
	var ring_counter := 0;
	var cycle_index: int = 0;
	while ring_counter < rings:
		var ring: ScatteredRing = SCATTERED_RING.instantiate();
		add_sibling(ring);
		
		ring.global_position = global_position;
		ring.velocity.x = cos(ring_angle) * ring_speed;
		ring.velocity.y = sin(ring_angle) * -ring_speed;
		
		if ring_flip:
			ring.velocity.x *= -1;
			ring_angle += add_angle;
		ring_flip = !ring_flip;
		
		ring_counter += 1;
		if ring_angle >= cycle_angle:
			if cycle_index == 0:
				ring_speed = 2.0 * 60.0;
			elif cycle_index == 1:
				ring_speed = 4.25 * 60.0;
				add_angle /= 2.0;
			else:
				await get_tree().create_timer(0.01).timeout;
				ring_speed += 0.125 * 60.0;
				if cycle_index < 10:
					add_angle /= 2 ** (2 ** -8);
				
			ring_angle = RING_STARTING_ANGLE;
			cycle_index += 1;
			

func kill():
	if state != State.NORMAL:
		return;
	
	hurt_sound.play();
	
	invulnerable = 0;
	state = State.DEAD;
	velocity.y = DEAD_SPEED_Y;
	velocity.x = 0;
	dead_timer = 2;
	set_animation("dead");

func set_animation(anim: String):
	if sprite.animation != anim:
		sprite.play(anim);

func player_sprites(direction: float):
	if spindashing:
		set_animation("spindash");
	elif rolling || jumping:
		set_animation("spin");
	elif falling > COYOTE_TIME:
		if crouching:
			set_animation("crouch");
		elif velocity.y < -200 || (springing && velocity.y < 0):
			set_animation("spring");
		elif absf(ground_speed) >= RUN_SPEED:
			set_animation("run");
		else:
			set_animation("walk");
	else:
		if crouching:
			set_animation("crouch");
		elif direction == wall_dir && direction == facing_dir && on_wall > 0:
			set_animation("push");
		elif (absf(ground_speed) > SKID_SPEED || sprite.animation == "skid") && direction == -signf(ground_speed):
			if sprite.animation != "skid":
				skid_sound.play();
			set_animation("skid");
		elif (sprite.animation == "skid" && absf(ground_speed) < 50) || (sprite.animation == "skidturn" && sprite.frame < 1):
			set_animation("skidturn");
		elif absf(ground_speed) >= RUN_SPEED:
			set_animation("run");
		elif direction != 0 || absf(ground_speed) > 5:
			set_animation("walk");
		else:
			set_animation("stand");
	sprite.flip_h = facing_dir == -1;
	if sprite.animation == "spin":
		sprite.rotation = 0;
	else:
		sprite.rotation = lerp_angle(sprite.rotation, -ground_normal.angle_to(Vector2.UP), 0.25);
	
	if sprite.animation == "walk":
		sprite.speed_scale = 1.0 / (0.016 + max(0, 8 - absf(ground_speed) / 60.0));
	elif sprite.animation == "run":
		sprite.speed_scale = 1.0 / (0.016 + max(0, 8 - absf(ground_speed) / 70.0));
	elif sprite.animation == "spin":
		sprite.speed_scale = 1.0 / (0.016 + max(0, 4 - absf(ground_speed) / 120.0));
	elif sprite.animation == "push":
		sprite.speed_scale = 1.0 / (0.016 + max(0, 8 - absf(ground_speed) / 60.0 * 4));
	elif sprite.animation == "spindash":
		sprite.speed_scale = lerp(0.33, 1.0, spindash_charge / 10.0);
	else:
		sprite.speed_scale = 1;
	
	if sprite.animation != "skid" && skid_sound.playing:
		skid_sound.stop();

func _on_layer_switch(layer: int, grounded_only: bool):
	if grounded_only && falling: return;
	if state == State.DEBUG: return;
	terrain_layer = layer;
	update_layer();

func is_curled() -> bool:
	return rolling || jumping || spindashing;

func _on_touch_badnik(badnik: Node2D, bounce_type: Badnik.BounceType):
	if is_curled():
		if badnik.has_signal("hurt"):
			badnik.hurt.emit(self);
		if !is_on_floor():
			match bounce_type:
				Badnik.BounceType.NORMAL:
					emit_sudden_momentum_change();
					if global_position.y < badnik.global_position.y && velocity.y > 0:
						velocity.y *= -1;
					else:
						velocity.y -= signf(velocity.y) * 60;
				Badnik.BounceType.BOSS:
					emit_sudden_momentum_change();
					velocity.x *= -0.5;
					velocity.y *= -0.5;
	else:
		hurt(int(signf(badnik.global_position.x - global_position.x)));

func update_layer():
	collision_layer = LevelUtil.LAYER_PLAYER;
	collision_mask = terrain_layer;
	ceiling_normal_raycast.collision_mask = terrain_layer;
	ceiling_normal_raycast_2.collision_mask = terrain_layer;
	if !is_curled():
		collision_mask |= LevelUtil.LAYER_MONITORS;

func do_layer_color():
	var c = Color.BLACK;
	if collision_layer & (1 << 0):
		c = Color(c.r, c.g + 0.5, c.b + 1);
	if collision_layer & (1 << 1):
		c = Color(c.r + 1, c.g + 0.5, c.b);
	c.a8 = 100;
	shape.debug_color = c;

func emit_sudden_momentum_change() -> void:
	sudden_momentum_change.emit();

func _input(ev: InputEvent):
	if ev.is_action_pressed("player_jump") && !ev.is_echo():
		jump_pressed = true;

signal touch_badnik(badnik: Node2D, bounce_type: Badnik.BounceType);
## Instantly records a player trail position when emitted.
signal sudden_momentum_change();
