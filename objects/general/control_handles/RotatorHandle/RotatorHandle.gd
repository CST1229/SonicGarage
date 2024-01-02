extends Control

# a control handle that lets you rotate an object

@export_range(0, 6.28319) var snap: float = deg_to_rad(45);
@export var target: Node2D;

@onready var panel: Panel = $Panel;

var dragging: bool = false;
var drag_offset: Vector2 = Vector2.ZERO;

func _ready():
	pass # Replace with function body.

func _process(_delta: float):
	if dragging:
		var target_pos := target.global_position;
		var mouse_pos := target.get_global_mouse_position() + drag_offset;
		
		var angle: float = target_pos.angle_to_point(mouse_pos) + deg_to_rad(90);
		if snap > 0.0:
			angle = roundf(angle / snap) * snap;
		target.rotation = angle;
		
		if !Input.is_action_pressed("editor_click"):
			dragging = false;
	queue_redraw();

func _gui_input(event: InputEvent):
	if !dragging:
		if event.is_action_pressed("editor_click"):
			drag_offset = (panel.position + panel.size * 0.5) - panel.get_local_mouse_position();
			dragging = true;
