extends AnimatableBody2D

@onready var sprite = $sprite;
@onready var pop_sound = $sound;
@onready var hitbox = $hitbox;

const items = {
	ring = preload("res://objects/level/Monitor/items/MonitorRing.gd"),
	eggman = preload("res://objects/level/Monitor/items/MonitorEggman.gd"),
};

var gravity := 0.0;

@export var item := &"ring":
	set(value):
		item = value;
		update_item();
var item_node: AnimatedSprite2D;

var container: LevelContainer;

var velocity: Vector2 = Vector2.ZERO;

func _ready():
	if !item_node:
		update_item();
	sprite.play("default");

func update_item():
	if item_node:
		item_node.queue_free();
	if item:
		item_node = AnimatedSprite2D.new();
		item_node.script = items[item];
		item_node.position.y = -2;
		item_node.container = container;
		add_child(item_node);

func _physics_process(delta: float):
	if gravity == 0.0:
		return;
	velocity.y += gravity * delta;
	var collision := move_and_collide(velocity * delta);
	if collision:
		velocity.y = 0;

func pop(player: Player):
	LevelUtil.pop(self);
	if item_node:
		item_node.pop(player);
	sprite.play("broken");
	pop_sound.play();
	
	hitbox.queue_free();
	collision_layer = 0;
	collision_mask &= ~(Global.LAYER_PLAYER | Global.LAYER_MONITORS);

func on_hit_hitbox(body: Node2D):
	if !(body is Player):
		return;
	var player: Player = body as Player;
	
	if player.velocity.y < 0 && (player.falling >= 0.075 || player.jumping):
		if player.global_position.y >= (global_position.y + 16):
			velocity.y = -1.5 * 60;
			gravity = 0.21875 * 60 * 60;
			player.velocity.y *= -1.0;
		return;
	if !player.is_curled():
		return;
	
	player.velocity.y *= -1.0;
	pop(player);

func serialize():
	return {
		id = "monitor",
		x = position.x,
		y = position.y,
		item = item,
	};
func deserialize(json: Dictionary):
	position.x = json.x;
	position.y = json.y;
	item = json.item;
