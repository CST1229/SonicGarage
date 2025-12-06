extends StaticBody2D

@onready var spike_sound = $spike_sound;

func play_sound():
	spike_sound.play();

func _on_hurtbox_touched(node: Node2D):
	if node is Player:
		node.hurt();

func serialize() -> Dictionary:
	return {
		x = position.x,
		y = position.y,
		rotation = rotation,
	};
func deserialize(json: Dictionary) -> void:
	position.x = json.x;
	position.y = json.y;
	rotation = json.rotation;
