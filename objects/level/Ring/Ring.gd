extends Node2D

@onready var sprite = $sprite;
var container: LevelContainer;

func _ready():
	if !container || !container.editor_mode:
		sprite.play(&"spin");

func collect(_body: Node2D):
	if sprite.animation != &"collect":
		if Global.level_manager: Global.level_manager.rings += 1;
		sprite.play(&"collect");
		GlobalSounds.play_ring();

func animation_finished():
	if sprite.animation == &"collect":
		queue_free();

func serialize():
	return {
		id = "ring",
		x = position.x,
		y = position.y
	};
func deserialize(json: Dictionary):
	position.x = json.x;
	position.y = json.y;
