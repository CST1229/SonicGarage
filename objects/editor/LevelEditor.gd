extends Node2D

@export var container: LevelContainer = null;
@export var camera: Camera2D = null;

@export var terrain_tools: Node = null;
@export var object_tools: Node = null;

enum DrawingMode {
	NONE,
	LINE,
	MOVE_VERT,
	RECT_SELECT,
}

enum Mode {
	TERRAIN,
	OBJECTS,
}

enum Tool {
	SELECT,
	LINE,
	OBJECT_SELECT,
}

var drawing: DrawingMode = DrawingMode.NONE;
var drawing_polygon: Array[Vertex] = [];
var selected_verts: Array[Vertex] = [];
var snapped_vert;

var mode: Mode = Mode.TERRAIN;
var tool: Tool = Tool.SELECT;

var grid_size: float = 8;
const VERT_SNAP: float = 10 ** 2;

const SCROLL_SPEED = 200;

var mouse_pos: Vector2 = Vector2.ZERO;
var actual_mp: Vector2 = Vector2.ZERO;
var mouse_move: Vector2 = Vector2.ZERO;

var select_origin: Vector2 = Vector2.ZERO;
var select_rect: Rect2;

const DRAWING_LINE_COLOR: Color = Color("ffffff88");

const POLYGON_SCENE = preload("res://objects/LevelContainer/Polygon.tscn");

var hovering_over_gui: bool = false;

func _ready():
	_process(0.33);

func _enter_tree():
	Global.editor_node = null;
func _exit_tree():
	if Global.editor_node == self:
		Global.editor_node = null;

func _draw():
	if drawing == DrawingMode.NONE:
		if (tool == Tool.LINE || (snapped_vert != null && !snapped_vert.selected)) && !hovering_over_gui:
			EditorLib.draw_vert(self, mouse_pos, 0.5);
	elif drawing == DrawingMode.LINE:
		var polyline = PackedVector2Array();
		for vert in drawing_polygon:
			polyline.append(vert.position);
		if !hovering_over_gui: polyline.append(mouse_pos);
		draw_polyline(polyline, DRAWING_LINE_COLOR, 3, false);
		for vert in drawing_polygon:
			EditorLib.draw_vert(self, vert.position);
		if !hovering_over_gui: EditorLib.draw_vert(self, mouse_pos, 0.5);
	elif drawing == DrawingMode.RECT_SELECT:
		draw_rect(select_rect, Color.WHITE, false, 2);

func finish_drawing(cancel: bool):
	if drawing == DrawingMode.NONE: return;
	if cancel:
		drawing = DrawingMode.NONE;
		drawing_polygon.clear();
		return;
	
	if drawing == DrawingMode.LINE:
		if drawing_polygon.size() > 2:
			var new_poly = drawing_polygon.duplicate();
			var poly = POLYGON_SCENE.instantiate();
			poly.container = container;
			for vert in new_poly:
				vert.polygon = poly;
			poly.vertices = new_poly;
			container.polygons.add_child(poly);
	
	drawing = DrawingMode.NONE;
	drawing_polygon.clear();

func _process(delta):
	if !container: return;
	
	actual_mp = get_local_mouse_position();
	var old_mouse_pos = mouse_pos;
	mouse_pos = actual_mp.snapped(Vector2(grid_size, grid_size));
	
	var snapped_dist = INF;
	snapped_vert = null;
	for poly in container.polygons.get_children():
		for vert in poly.vertices:
			var dist = vert.position.distance_squared_to(actual_mp);
			if dist < VERT_SNAP && dist < snapped_dist:
				snapped_dist = dist;
				mouse_pos = vert.position;
				snapped_vert = vert;
	
	mouse_move = mouse_pos - old_mouse_pos;
	
	if camera:
		var scroll_x = Input.get_axis("editor_scroll_left", "editor_scroll_right");
		var scroll_y = Input.get_axis("editor_scroll_up", "editor_scroll_down");
		if Input.is_action_pressed("editor_scroll_fast"):
			scroll_x *= 3;
			scroll_y *= 3;
		camera.position.x += scroll_x * SCROLL_SPEED * delta;
		camera.position.y += scroll_y * SCROLL_SPEED * delta;
	
	if drawing == DrawingMode.MOVE_VERT:
		var polys: Array[Polygon] = [];
		if Input.is_action_pressed("editor_click"):
			for vert in selected_verts:
				vert.position += mouse_move;
				if !polys.has(vert.polygon):
					polys.append(vert.polygon);
		else:
			# If the vertex was dragged on top of a neighboring vertex, delete it
			for vert in selected_verts:
				var poly = vert.polygon;
				if poly.is_queued_for_deletion(): continue;
				var verts = poly.vertices;
				var vert_index = verts.find(vert);
				var vpos = vert.position;
				if verts[(vert_index - 1) % verts.size()].position == vpos:
					EditorLib.delete_vertex(vert);
					selected_verts.erase(vert);
				elif verts[(vert_index + 1) % verts.size()].position == vpos:
					EditorLib.delete_vertex(vert);
					selected_verts.erase(vert);
				if !polys.has(poly):
					polys.append(poly);
			drawing = DrawingMode.NONE;
		for poly in polys:
			poly.update_polygon();
	elif drawing == DrawingMode.RECT_SELECT:
		select_rect = Rect2(select_origin, actual_mp - select_origin).abs();
		if !Input.is_action_pressed("editor_click"):
			var polys: Array[Polygon] = [];
			for poly in container.polygons.get_children():
				for vert in poly.vertices:
					if select_rect.has_point(vert.position):
						select_vert(vert);
						if !polys.has(poly): polys.append(poly);
			for poly in polys:
				poly.update_polygon();
			
			drawing = DrawingMode.NONE;
	
	if Input.is_action_pressed("editor_delete"):
		var polys: Array[Polygon] = [];
		for vert in selected_verts:
			if vert.polygon.is_queued_for_deletion(): continue;
			EditorLib.delete_vertex(vert);
			if !polys.has(vert.polygon):
				polys.append(vert.polygon);
		for poly in polys:
			poly.update_polygon();
		deselect_verts();
	
	queue_redraw();

# things that should only run while not hovering hover gui
# (mostly clicking)
func _unhandled_input(ev: InputEvent):
	if drawing == DrawingMode.NONE:
		if ev.is_action_pressed("editor_click"):
			if tool == Tool.SELECT:
				if snapped_vert != null:
					if !Input.is_action_pressed("editor_multiselect") && !snapped_vert.selected:
						deselect_verts();
					if !Input.is_action_pressed("editor_multiselect") || !snapped_vert.selected:
						select_vert(snapped_vert);
						drawing = DrawingMode.MOVE_VERT;
					else:
						deselect_vert(snapped_vert);
				else:
					if !Input.is_action_pressed("editor_multiselect"): deselect_verts();
					select_origin = actual_mp;
					select_rect = Rect2(actual_mp, Vector2.ZERO);
					drawing = DrawingMode.RECT_SELECT;
			elif tool == Tool.LINE:
				drawing_polygon = [EditorLib.create_vertex(mouse_pos)];
				drawing = DrawingMode.LINE;
	elif drawing == DrawingMode.LINE:
		if actual_mp.distance_squared_to(drawing_polygon[0].position) <= VERT_SNAP:
			mouse_pos = drawing_polygon[0].position;
		
		if ev.is_action_pressed("editor_cancel"):
			finish_drawing(true);
		elif ev.is_action_pressed("editor_click"):
			if mouse_pos == drawing_polygon[0].position:
				finish_drawing(false);
			elif drawing_polygon.back().position != mouse_pos:
				drawing_polygon.append(EditorLib.create_vertex(mouse_pos));


# some gui stuff
func _on_mouse_hover_gui():
	hovering_over_gui = true;
func _on_mouse_dehover_gui():
	hovering_over_gui = false;
func on_menu_press(id: int):
	match id:
		0: # Save Level
			Global.load_level = container.serialize();
			DisplayServer.file_dialog_show(
				"Save Level", "",
				"level.sgl", false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
				PackedStringArray(["*.sgl"]),
				EditorLib.save_level
			);
		1: # Load Level
			DisplayServer.file_dialog_show(
				"Load Level", "",
				"level.sgl", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
				PackedStringArray(["*.sgl", "*"]),
				EditorLib.load_level_editor
			);
		2: # Clear Level
			Global.load_level = null;
			get_tree().reload_current_scene();
		3: # Exit
			Global.load_level = container.serialize();
			get_tree().change_scene_to_file("res://scenes/TitleScreen/TitleScreen.tscn");

# utilities
func deselect_verts():
	for vert in selected_verts:
		vert.selected = false;
		if vert.polygon: vert.polygon.queue_redraw();
	selected_verts.clear();
func deselect_vert(vert: Vertex):
	vert.selected = false;
	selected_verts.erase(vert);
	if vert.polygon: vert.polygon.queue_redraw();
func select_vert(vert: Vertex):
	vert.selected = true;
	if !selected_verts.has(vert):
		selected_verts.append(vert);
	if vert.polygon: vert.polygon.queue_redraw();

# mode switching
func select_tool(t: Tool):
	if tool == t: return;
	deselect_verts();
	finish_drawing(true);
	tool = t;
func select_mode(m: Mode, t: Tool):
	if mode == m: return;
	mode = m;
	deselect_verts();
	finish_drawing(true);
	tool = t;
	
	tools_visible(terrain_tools, Mode.TERRAIN)
	tools_visible(object_tools, Mode.OBJECTS)
func tools_visible(tools: Node, m: Mode):
	if tools:
		tools.visible = mode == m;

# tools
func select_tool_pressed():
	select_tool(Tool.SELECT);
func line_tool_pressed():
	select_tool(Tool.LINE);
func object_select_tool_pressed():
	pass # Replace with function body.

# modes
func terrain_mode_pressed():
	select_mode(Mode.TERRAIN, Tool.SELECT);
func objects_mode_pressed():
	select_mode(Mode.OBJECTS, Tool.OBJECT_SELECT);
