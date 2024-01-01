extends CharacterBody2D
class_name ScatteredRing

const RING_SCENE = preload("res://objects/level/Ring/Ring.tscn");

const GRAVITY = 0.09375 * 60 * 60;
const LIFESPAN = 4.25;

@onready var ring: Ring;

var timer: float = 0.0;

func _ready():
	timer = LIFESPAN;
	
	ring = RING_SCENE.instantiate();
	add_child(ring);
	ring.collectable = false;

func _process(delta: float):
	if !ring || ring.is_queued_for_deletion():
		queue_free();
		return;
	if ring.sprite.animation == &"collect":
		return;
	
	if (LIFESPAN - timer) >= 1.5:
		ring.collectable = true;
	
	velocity.y += GRAVITY * delta;
	
	var old_vel := velocity;
	move_and_slide();
	
	if is_on_wall():
		velocity.x = old_vel.x * -0.75;
	if is_on_floor() || is_on_ceiling():
		velocity.y = old_vel.y * -0.75;
	
	ring.sprite.speed_scale = lerpf(4, 0, (LIFESPAN - timer) / 4.25);
	
	timer = move_toward(timer, 0, delta);
	if timer <= 0:
		queue_free();
