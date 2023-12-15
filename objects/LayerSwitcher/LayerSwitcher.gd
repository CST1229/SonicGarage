@tool
extends Area2D

var shape: Node2D;

var _layer: int = 1;
@export_flags_2d_physics var layer: int:
	get:
		return _layer;
	set(value):
		_layer = value;
		do_color();
@export var grounded_only: bool = false;

func do_color():
	var c = Color.BLACK;
	if layer & (1 << 0):
		c = Color(c.r, c.g + 0.5, c.b + 1);
	if layer & (1 << 1):
		c = Color(c.r + 1, c.g + 0.5, c.b);
	c.a8 = 100;
	if shape: shape.debug_color = c;

func _ready():
	shape = $CollisionShape2D;
	do_color();

func _on_enter(body: Node2D):
	if !Engine.is_editor_hint():
		if body.has_signal(&"layer_switch"):
			body.layer_switch.emit(layer, grounded_only);
