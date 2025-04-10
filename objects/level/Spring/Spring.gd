extends Node2D
class_name Spring

@export var direction := SpringDirection.VERTICAL;
@export var type := &"yellow";
@export var flip_h := false;
@export var flip_v := false;

enum SpringDirection {
	VERTICAL = 0,
	DIAGONAL = 1,
	HORIZONTAL = 2,
}

@onready var sprite: AnimatedSprite2D = $sprite;
@onready var sound: AudioStreamPlayer = $sound;

@onready var body: StaticBody2D = $body;
@onready var shape: CollisionShape2D = $body/shape;
@onready var hitbox: Touchbox = $body/hitbox;
@onready var hitbox_shape: CollisionShape2D = $body/hitbox/hitbox_shape;
@onready var hitbox_diagonal: Area2D = $body/hitbox_diagonal;
@onready var bounds: EditorObjectBounds = $EditorObjectBounds;

func _ready():
	update_spring();

func update_spring():
	sprite.flip_h = flip_h;
	sprite.flip_v = flip_v;
	sprite.rotation = 0;
	
	body.rotation = 0;
	if direction == SpringDirection.DIAGONAL:
		shape.disabled = true;
		shape.visible = false;
		hitbox.visible = false;
		hitbox_diagonal.visible = true;
		hitbox_diagonal.process_mode = Node.PROCESS_MODE_INHERIT;
		hitbox.process_mode = Node.PROCESS_MODE_DISABLED;
		if bounds:
			bounds.size = Vector2(32, 32);
			bounds.position = Vector2(-8 if flip_h else 8, 8 if flip_v else -8);
		hitbox_diagonal.position = Vector2(-4 if flip_h else 4, 4 if flip_v else -4);
	else:
		shape.disabled = false;
		shape.visible = true;
		hitbox.visible = true;
		hitbox_diagonal.visible = false;
		hitbox.process_mode = Node.PROCESS_MODE_INHERIT;
		hitbox_diagonal.process_mode = Node.PROCESS_MODE_DISABLED;
		if direction == SpringDirection.HORIZONTAL:
			sprite.flip_h = flip_v;
			sprite.flip_v = flip_h;
			sprite.rotation = deg_to_rad(90);
			body.rotation = deg_to_rad(90);
			if flip_h:
				body.rotation += deg_to_rad(180);
		else:
			if flip_v:
				body.rotation = deg_to_rad(180);
		if bounds:
			bounds.position = Vector2(0, 0);
			bounds.size = Vector2(32, 16);
	if bounds:
		bounds.rotation = sprite.rotation;
		bounds.queue_redraw();
	
	var direction_string := "diagonal" if direction == SpringDirection.DIAGONAL else "vertical";
	sprite.animation = &"{0}_{1}".format([type, direction_string]);
	sprite.stop();
	sprite.frame = 0;
	sprite.frame_progress = 0;

func _on_sprite_animation_finished():
	sprite.frame = 0;
	sprite.frame_progress = 0;

func is_diagonal():
	return direction == SpringDirection.DIAGONAL;

func spring(_node: Node2D):
	sprite.frame = 1;
	sprite.frame_progress = 0;
	sprite.play(sprite.animation);
	sound.play();
	if _node is PhysicsBody2D:
		var node: PhysicsBody2D = _node as PhysicsBody2D;
		var mirror: Vector2 = Vector2(-1 if flip_h else 1, -1 if flip_v else 1);
		var force := 16.0 if type == &"red" else 10.0;
		if direction == SpringDirection.DIAGONAL:
			node.global_position += Vector2(24, -24) * mirror;
			node.velocity = mirror * force * 60 * Vector2(1, -1);
		elif direction == SpringDirection.HORIZONTAL:
			node.velocity.x = force * 60 * mirror.x;
		else:
			node.velocity.y = -force * 60 * mirror.y;
		
		if node is Player:
			var player: Player = node as Player;
			player.just_sprung = 2;
			if direction != SpringDirection.HORIZONTAL && player.ground_normal.y < -0.1:
				player.falling = 100;
				player.rolling = false;
				player.crouching = false;
				player.spindashing = false;
				player.jumping = false;
				player.springing = true;
			if direction == Spring.SpringDirection.HORIZONTAL && player.on_floor >= 0.1:
				player.controllock_timer = 16.0 / 60.0;
				player.facing_dir = -1 if flip_h else 1;

func serialize():
	return {
		id = "spring",
		x = position.x,
		y = position.y,
		direction = direction,
		type = type,
		flip_h = flip_h,
		flip_v = flip_v,
	};

func deserialize(json: Dictionary):
	position.x = json.x;
	position.y = json.y;
	direction = json.direction;
	type = json.type;
	flip_h = json.flip_h;
	flip_v = json.flip_v;
	if sprite && shape: update_spring();
