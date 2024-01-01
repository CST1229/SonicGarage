@tool
extends Area2D
class_name EditorObjectBounds

@onready var shape: CollisionShape2D = $shape;
@export var size: Vector2 = Vector2.ZERO:
	set(value):
		size = value;
		if shape && size.x >= 0 && size.y >= 0: shape.shape.size = size;
		queue_redraw();

@export_range(0, 1) var outline_alpha := 1.0;

func _draw():
	if Engine.is_editor_hint(): return;
	var parent = get_parent();
	if !parent: return;
	if !parent.is_in_group(&"selected_objects"): return;
	draw_rect(Rect2(position - size / 2, size), Color(1, 1, 1, outline_alpha), false, 1);

func _ready():
	if !Engine.is_editor_hint():
		var container: LevelContainer;
		var parent = get_parent();
		if "container" in parent:
			container = parent.container;
		else:
			parent = get_tree().current_scene as EditorRoom;
			if "level_container" in parent:
				container = parent.level_container;
			else:
				queue_free();
				return;
		if !container || !container.editor_mode:
			queue_free();
			return;
	shape.shape = shape.shape.duplicate();
	if shape: shape.shape.size = size;
