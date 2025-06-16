## A Genesis-ish fade. Has to be controlled manually.
class_name Fade
extends Control

@export var fade_rect: ColorRect;
@export var tint_rect: ColorRect;

@export var is_white: bool = false:
	get:
		return is_white;
	set(value):
		is_white = value;
		if is_white:
			fade_rect.color = Color.WHITE;
			tint_rect.color = Color.BLUE;
		else:
			fade_rect.color = Color.BLACK;
			tint_rect.color = Color.YELLOW;

@export var fade: float = 0.0:
	get:
		return fade;
	set(value):
		fade = value;
		tint_rect.modulate.a = value;
		fade_rect.modulate.a = value;

@export var affects_volume = false;

func _process(_delta: float) -> void:
	if affects_volume:
		Music.fade_volume = 1.0 - fade;
