## A Genesis-ish fade. Has to be controlled manually.
@tool
class_name Fade
extends Control

@onready var tint_rect: ColorRect = $TintRect
@onready var fade_rect: ColorRect = $FadeRect

## This fade's current tween.
var tween: Tween;

@export var is_white: bool = false:
	get:
		return is_white;
	set(value):
		is_white = value;
		if tint_rect && fade_rect:
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
		affects_volume = affects_volume;
		if tint_rect && fade_rect:
			tint_rect.modulate.a = value;
			fade_rect.modulate.a = value;

@export var affects_volume = false:
	set(value):
		affects_volume = value;
		if !Engine.is_editor_hint():
			Music.fade_volume = 1.0 - fade if affects_volume else 1.0;

func _ready():
	# do setters
	is_white = is_white;
	fade = fade;

func _on_button_pressed() -> void:
	clicked.emit();

signal clicked
