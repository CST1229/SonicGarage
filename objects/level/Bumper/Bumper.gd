extends Node2D

@onready var sprite: AnimatedSprite2D = $sprite;
@onready var sound: AudioStreamPlayer2D = $sound;
var container: LevelContainer;

func serialize() -> Dictionary:
	return {
		x = position.x,
		y = position.y,
	};
func deserialize(json: Dictionary) -> void:
	position.x = json.x;
	position.y = json.y;


func bump(body: Node2D) -> void:
	if "velocity" not in body:
		return;
	sprite.play("bump");
	sound.play();
	body.velocity = (7 * 60.0) * (body.global_position - global_position).normalized();
