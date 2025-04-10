## A control handle that lets you rotate and change the type of a [Spring].
extends Control

var snap: float = deg_to_rad(45);
@export var target: Spring;

const YELLOW_Y = 32;
const RED_Y = 64;

@onready var panel: Panel = $Panel;
@onready var container = get_parent();

var dragging: bool = false;
var drag_offset: Vector2 = Vector2.ZERO;

func _ready():
	do_angle();

func _process(_delta: float):
	if dragging:
		var target_pos := target.global_position;
		var mouse_pos := target.get_global_mouse_position() + drag_offset;
		
		var angle: float = target_pos.angle_to_point(mouse_pos) + deg_to_rad(90);
		if snap > 0.0:
			angle = snappedf(angle, snap);
		
		var distance = target_pos.distance_to(mouse_pos);
		
		var vector: Vector2 = Vector2.from_angle(-angle).rotated(deg_to_rad(90));
		target.flip_h = vector.x < -0.01;
		target.flip_v = vector.y < -0.01;
		if distance >= (RED_Y - 16):
			target.type = &"red";
		else:
			target.type = &"yellow";
		if absf(vector.x) < 0.01:
			target.direction = Spring.SpringDirection.VERTICAL;
		elif absf(vector.y) < 0.01:
			target.direction = Spring.SpringDirection.HORIZONTAL;
		else:
			target.direction = Spring.SpringDirection.DIAGONAL;
		target.update_spring();
		do_angle();
		
		if !Input.is_action_pressed("editor_click"):
			dragging = false;
	queue_redraw();

func do_angle():
	var vector: Vector2 = Vector2.UP;
	match target.direction:
		Spring.SpringDirection.HORIZONTAL:
			vector = Vector2.RIGHT;
		Spring.SpringDirection.DIAGONAL:
			vector = Vector2.from_angle(deg_to_rad(-45));
	if target.flip_h:
		vector.x *= -1;
	if target.flip_v:
		vector.y *= -1;
	container.rotation = vector.angle() + deg_to_rad(90);
	position.y = -RED_Y if target.type == &"red" else -YELLOW_Y;

func _gui_input(event: InputEvent):
	if !dragging:
		if event.is_action_pressed("editor_click"):
			drag_offset = (panel.position + panel.size * 0.5) - panel.get_local_mouse_position();
			dragging = true;
