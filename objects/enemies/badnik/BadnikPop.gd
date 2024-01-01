extends AnimatedSprite2D
class_name BadnikPop

@export var play_sound := false;
@onready var sound: AudioStreamPlayer = $sound;

func _ready():
	play("pop");
	if play_sound:
		sound.play();

func _on_animation_finished():
	queue_free();
