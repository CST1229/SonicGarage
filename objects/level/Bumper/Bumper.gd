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
	var hit_vel := (7 * 60.0) * (body.global_position - global_position).normalized();
	if body.get_meta("last_bumper_hit_frame", -1) != Engine.get_physics_frames():
		body.set_meta("bumper_hit_velocities", []);
		body.set_meta("last_bumper_hit_frame", Engine.get_physics_frames())
	
	var hit_velocities = body.get_meta("bumper_hit_velocities");
	
	hit_velocities.append(hit_vel);
	# average velocity between all bumpers hit this frame
	body.velocity = hit_velocities.reduce(func(a, b):
		return a + b;
	) / float(hit_velocities.size());
