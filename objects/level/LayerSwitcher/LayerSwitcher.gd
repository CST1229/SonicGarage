@tool
extends Node2D

# switches the player between layers.
# most of this is editor-related stuff

@onready var area: Area2D = $area;
@onready var shape: CollisionShape2D = $area/shape;
@onready var bounds: EditorObjectBounds = $bounds;

var container: LevelContainer;

@onready var layer_handle: Button = $HandleContainer/LayerHandle;
@onready var grounded_only_handle: Button = $HandleContainer/GroundedOnlyHandle;

@export var size: Vector2 = Vector2(32, 32):
	set(value):
		size = value;
		set_size();
		queue_redraw();

var layer_num: int = 1;
@export_enum("a", "b", "ab") var layer: String = "a":
	set(value):
		layer = value;
		layer_num = 0;
		match value:
			"a": layer_num = Global.LAYER_A;
			"b": layer_num = Global.LAYER_B;
			"ab": layer_num = Global.LAYER_A | Global.LAYER_B;
		update_icons();
		queue_redraw();

# "grounded only" layer switchers only work when the player is on the ground
@export var grounded_only: bool = false:
	set(value):
		grounded_only = value;
		update_icons();

func get_color():
	var c = Color.BLACK;
	if layer_num & Global.LAYER_A:
		c = Color(c.r, c.g + 0.5, c.b + 1);
	if layer_num & Global.LAYER_B:
		c = Color(c.r + 1, c.g + 0.5, c.b);
	return c;

func _draw():
	if Engine.is_editor_hint() || !container || !container.editor_mode: return;
	var color = get_color();
	var transparent_color = Color(color.r, color.g, color.b, 0.25);
	var rect = Rect2(-size / 2.0, size);
	draw_rect(rect, transparent_color, true);
	draw_rect(rect, color, false, 1);

func _ready():
	area.area_entered.connect(_on_enter);
	area.body_entered.connect(_on_enter);
	set_size();
	update_icons();

func set_size():
	if area: area.scale = size / Vector2(16, 16);
	if bounds: bounds.size = size;

func update_icons():
	if grounded_only_handle:
		if grounded_only:
			grounded_only_handle.icon = preload("res://sprites/icons/handle/grounded_only.png");
			grounded_only_handle.tooltip_text = "Grounded-only: On";
		else:
			grounded_only_handle.icon = preload("res://sprites/icons/handle/air.png");
			grounded_only_handle.tooltip_text = "Grounded-only: Off";
	if layer_handle:
		match layer:
			"a":
				layer_handle.icon = preload("res://sprites/icons/handle/layer_a.png");
				layer_handle.tooltip_text = "Switches to layer A";
			"b":
				layer_handle.icon = preload("res://sprites/icons/handle/layer_b.png");
				layer_handle.tooltip_text = "Switches to layer B";
			"ab":
				layer_handle.icon = preload("res://sprites/icons/handle/layer_ab.png");
				layer_handle.tooltip_text = "Switches to layer AB";
			"?":
				layer_handle.icon = preload("res://sprites/icons/handle/qmark.png");
				layer_handle.tooltip_text = "what";

func _on_enter(body: Node2D):
	if !Engine.is_editor_hint():
		if body.has_signal(&"layer_switch"):
			body.layer_switch.emit(layer_num, grounded_only);

func serialize():
	return {
		id = "layer_switcher",
		x = position.x,
		y = position.y,
		layer = layer,
		size = [size.x, size.y],
		grounded_only = grounded_only,
	};
func deserialize(json: Dictionary):
	position.x = json.x;
	position.y = json.y;
	size = Vector2(json.size[0], json.size[1]);
	grounded_only = json.grounded_only;
	layer = json.layer;


func layer_handle_pressed():
	match layer:
		"a": layer = "b";
		"b": layer = "ab";
		"ab": layer = "a";
		_: layer = "a";
func grounded_only_handle_pressed():
	grounded_only = !grounded_only;
