## An inner handle used by RectResizerHandle.
##
## This is what actually scales the object
## and is shown to the user.
extends Control

const HANDLE_RADIUS = 4;

var handle: Vector2 = Vector2.ONE;
var dragging: bool = false;

var target: Node2D;
var snap: Vector2 = Vector2.ONE;

@onready var resizer = get_parent();

func _ready():
	# center it
	offset_left = -HANDLE_RADIUS;
	offset_right = HANDLE_RADIUS;
	offset_top = -HANDLE_RADIUS;
	offset_bottom = HANDLE_RADIUS;

func _process(_delta: float):
	if dragging:
		var origin = target.global_position + target.size * -handle;
		var mouse_pos = get_global_mouse_position().snapped(snap);
		# this is a TOTAL HOT MESS
		# and i had like 50 brain attacks while writing and debugging this code
		if Input.is_action_pressed("editor_click"):
			var d_handle = handle * 2;
			var rect = Rect2(origin, (mouse_pos - origin) * d_handle);
			rect.position += rect.size * (handle - Vector2(0.5, 0.5));
			
			var old_size = target.size;
			var old_pos = target.global_position;
			target.size = rect.size;
			target.global_position = rect.position + (rect.size / 2.0);
			
			# fix cardinal resizing setting the object's width/height to 0
			if handle.x == 0:
				target.size.x = old_size.x;
				target.global_position.x = old_pos.x;
			if handle.y == 0:
				target.size.y = old_size.y;
				target.global_position.y = old_pos.y;
			
			# fix negative sizes
			# i think LayerSwitcher is fine with negative sizes,
			# but handles break with it and it probably also breaks
			# a lot of other stuff
			if resizer && (target.size.x < 0 || target.size.y < 0):
				var opposite_handle = handle;
				if target.size.x < 0: opposite_handle.x *= -1;
				if target.size.y < 0: opposite_handle.y *= -1;
				
				rect = Rect2(target.global_position - target.size / 2.0, target.size).abs();
				target.size = rect.size;
				target.global_position = rect.position + (rect.size / 2.0);
				
				var opposite_node = resizer.handle_nodes[opposite_handle];
				dragging = false;
				opposite_node.dragging = true;
				opposite_node._process(_delta);
			if resizer:
				resizer.get_parent().update_size();
		else:
			dragging = false;

func _gui_input(event: InputEvent):
	if event.is_action_pressed("editor_click"):
		dragging = true;

func _draw():
	draw_style_box(
		Global.UI_THEME.get_stylebox(&"normal", &"HandleButton"),
		Rect2(Vector2.ZERO, size)
	);
