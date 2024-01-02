extends StaticBody2D

@onready var spike_sound = $spike_sound;

func play_sound():
	spike_sound.play();

func serialize():
	return {
		id = "spike",
		x = position.x,
		y = position.y,
		rotation = rotation,
	};
func deserialize(json: Dictionary):
	position.x = json.x;
	position.y = json.y;
	rotation = json.rotation;
