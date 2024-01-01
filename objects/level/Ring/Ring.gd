extends Node2D
class_name Ring

@onready var sprite: AnimatedSprite2D = $sprite;
var container: LevelContainer;

@export var collectable: bool = true;

func _ready():
	if !container || !container.editor_mode:
		sprite.play(&"spin");

func collect(_body: Node2D):
	if !collectable:
		return;
	
	if _body is Player:
		if _body.state != Player.State.NORMAL:
			return;
		if _body.invulnerable > 1:
			return;
	
	if sprite.animation != &"collect":
		if Global.level_manager: Global.level_manager.rings += 1;
		sprite.play(&"collect");
		sprite.speed_scale = 1;
		GlobalSounds.play_ring();

func animation_finished():
	if sprite.animation == &"collect":
		queue_free();

func serialize():
	return {
		id = "ring",
		x = position.x,
		y = position.y,
	};
func deserialize(json: Dictionary):
	position.x = json.x;
	position.y = json.y;
