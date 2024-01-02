extends Node2D
class_name LevelEditor

@export var container: LevelContainer = null;
@export var camera: Camera2D = null;

# the object detector looks for objects or polygons
# (this is used when selecting them)
@onready var object_detector: Area2D = $object_detector;
@onready var object_detector_shape: CollisionShape2D = $object_detector/shape;

enum Mode {
	TERRAIN,
	OBJECTS,
}

enum Tool {
	POLY_SELECT,
	VERT_SELECT,
	LINE,
	
	OBJECT_SELECT,
	OBJECT_PLACE,
}

enum DrawingMode {
	NONE,
	LINE,
	MOVE_VERT,
	RECT_SELECT,
	
	MOVE_OBJECT,
}

var drawing: DrawingMode = DrawingMode.NONE;
var drawing_polygon: Array[Vertex] = [];
var selected_verts: Array[Vertex] = [];

# a list of nodes to not select/deselect in the rect select mode.
# when multiselecting this is set to the list of already selected objects
# so you don't deselect objects you already selected
var ignore_select_objects: Array[Node] = [];

var grid_size: float = 8;
const SCROLL_SPEED = 200;

# vertex stuff
var snapped_vert: Vertex;
const VERT_SNAP: float = 10 ** 2;

var mode: Mode = Mode.TERRAIN;
var tool: Tool = Tool.VERT_SELECT;

# mouse things
var mouse_pos: Vector2 = Vector2.ZERO;
var actual_mp: Vector2 = Vector2.ZERO;
var mouse_move: Vector2 = Vector2.ZERO;

# rect select stuff
var select_origin: Vector2 = Vector2.ZERO;
var select_rect: Rect2;

# object to place
# setter does ghost object stuff
var place_object = null:
	set(value):
		place_object = value;
		if ghost_object:
			ghost_object.queue_free();
			ghost_object = null;
		if place_object != null:
			ghost_object = EditorLib.create_object(place_object, container);
			ghost_object.visible = !hovering_over_gui;
			ghost_object.modulate = Color(1, 1, 1, 0.5);
			add_child(ghost_object);
# the "ghost object" is the ghost of an object,
# used in the object place mode.
# it's actually a full-on instance of the object
var ghost_object: Node = null;

var hovering_over_gui: bool = false;

const DRAWING_LINE_COLOR: Color = Color("ffffff88");
const POLYGON_SCENE = preload("res://objects/essential/LevelContainer/Polygon.tscn");

func _ready():
	_process(0.16);
	object_detector.area_entered.connect(do_object_detector.bind(false));
	object_detector.area_exited.connect(do_object_detector.bind(true));
	object_detector.body_entered.connect(do_polygon_detector.bind(false));
	object_detector.body_exited.connect(do_polygon_detector.bind(true));
	selection_changed.emit();

func _draw():
	if drawing == DrawingMode.NONE && !hovering_over_gui:
		if (tool == Tool.LINE || (snapped_vert != null && !snapped_vert.selected)):
			EditorLib.draw_vert(self, mouse_pos, 0.5);
	elif drawing == DrawingMode.LINE:
		var polyline := PackedVector2Array();
		for vert in drawing_polygon:
			polyline.append(vert.position);
		if !hovering_over_gui: polyline.append(mouse_pos);
		if polyline.size() >= 2:
			draw_polyline(polyline, DRAWING_LINE_COLOR, 3, false);
		for vert in drawing_polygon:
			EditorLib.draw_vert(self, vert.position);
		if !hovering_over_gui: EditorLib.draw_vert(self, mouse_pos, 0.5);
	elif drawing == DrawingMode.RECT_SELECT:
		if select_rect.size.x > 2 && select_rect.size.y > 2:
			draw_rect(select_rect.grow(-1), Color.WHITE, false, 2);
		elif select_rect.size.x > 0 && select_rect.size.y > 0:
			draw_rect(select_rect, Color.WHITE, true);

func finish_drawing(cancel: bool):
	if drawing == DrawingMode.NONE: return;
	if cancel:
		drawing = DrawingMode.NONE;
		drawing_polygon.clear();
		return;
	
	if drawing == DrawingMode.LINE:
		if drawing_polygon.size() > 2:
			var new_poly := drawing_polygon.duplicate();
			var poly: Polygon = POLYGON_SCENE.instantiate();
			poly.container = container;
			for vert in new_poly:
				vert.polygon = poly;
			poly.vertices = new_poly;
			container.polygons.add_child(poly);
	
	drawing = DrawingMode.NONE;
	drawing_polygon.clear();

func _process(delta: float):
	if !container: return;
	
	actual_mp = get_local_mouse_position();
	var old_mouse_pos := mouse_pos;
	mouse_pos = actual_mp.snapped(Vector2(grid_size, grid_size));
	
	if mode == Mode.TERRAIN:
		object_detector.collision_layer = Global.LAYER_POLYGONS;
		object_detector.collision_mask = object_detector.collision_layer;
		if tool == Tool.VERT_SELECT || tool == Tool.LINE:
			var snapped_dist := INF;
			snapped_vert = null;
			for poly: Polygon in container.polygons.get_children():
				for vert: Vertex in poly.vertices:
					var dist := vert.position.distance_squared_to(actual_mp);
					if dist < VERT_SNAP && dist < snapped_dist:
						snapped_dist = dist;
						mouse_pos = vert.position;
						snapped_vert = vert;
		else:
			snapped_vert = null;
	else:
		object_detector.collision_layer = Global.LAYER_EDITOR_OBJECTS;
		object_detector.collision_mask = object_detector.collision_layer;
		snapped_vert = null;
	
	mouse_move = mouse_pos - old_mouse_pos;
	
	scroll_camera(delta);
	update_ghost_object();
	update_object_detector();
	
	if drawing == DrawingMode.MOVE_VERT:
		var polys: Array[Polygon] = [];
		if Input.is_action_pressed("editor_click"):
			for vert in selected_verts:
				vert.position += mouse_move;
				if !polys.has(vert.polygon):
					polys.append(vert.polygon);
		else:
			# If the vertex was dragged on top of a neighboring vertex, delete it
			for vert: Vertex in selected_verts:
				var poly := vert.polygon;
				if poly.is_queued_for_deletion(): continue;
				var verts := poly.vertices;
				var vert_index := verts.find(vert);
				var vpos := vert.position;
				if verts[(vert_index - 1) % verts.size()].position == vpos:
					EditorLib.delete_vertex(vert);
					selected_verts.erase(vert);
				elif verts[(vert_index + 1) % verts.size()].position == vpos:
					EditorLib.delete_vertex(vert);
					selected_verts.erase(vert);
				if !polys.has(poly):
					polys.append(poly);
			drawing = DrawingMode.NONE;
		for poly: Polygon in polys:
			poly.update_polygon();
	elif drawing == DrawingMode.RECT_SELECT:
		select_rect = Rect2(select_origin, actual_mp - select_origin).abs();
		update_object_detector();
		if !Input.is_action_pressed("editor_click"):
			if tool == Tool.VERT_SELECT:
				var polys: Array[Polygon] = [];
				for poly: Polygon in container.polygons.get_children():
					for vert: Vertex in poly.vertices:
						if select_rect.has_point(vert.position):
							select_vert(vert);
							if !polys.has(poly): polys.append(poly);
				for poly: Polygon in polys:
					poly.update_polygon();
				selection_changed.emit();
			drawing = DrawingMode.NONE;
	elif drawing == DrawingMode.MOVE_OBJECT:
		if Input.is_action_pressed("editor_click"):
			for obj: Node2D in get_tree().get_nodes_in_group(&"selected_objects"):
				obj.position += mouse_move;
			for obj: Polygon in get_tree().get_nodes_in_group(&"selected_polygons"):
				for vert: Vertex in obj.vertices:
					vert.position += mouse_move;
				obj.update_polygon();
		else:
			drawing = DrawingMode.NONE;
	
	handle_delete();
	queue_redraw();

func scroll_camera(delta: float):
	if camera:
		var scroll_x := Input.get_axis("editor_scroll_left", "editor_scroll_right");
		var scroll_y := Input.get_axis("editor_scroll_up", "editor_scroll_down");
		if Input.is_action_pressed("editor_scroll_fast"):
			scroll_x *= 3;
			scroll_y *= 3;
		camera.position.x += scroll_x * SCROLL_SPEED * delta;
		camera.position.y += scroll_y * SCROLL_SPEED * delta;

func update_ghost_object():
	if ghost_object:
		ghost_object.position = mouse_pos;
		ghost_object.visible = !hovering_over_gui;

func update_object_detector():
	if drawing != DrawingMode.RECT_SELECT:
		object_detector.position = actual_mp;
		object_detector_shape.shape.size = Vector2.ZERO;
	else:
		object_detector.position = select_rect.position + (select_rect.size / 2.0);
		object_detector_shape.shape.size = select_rect.size;

func handle_delete():
	if Input.is_action_pressed("editor_delete"):
		var polys: Array[Polygon] = [];
		for vert in selected_verts:
			if vert.polygon.is_queued_for_deletion(): continue;
			EditorLib.delete_vertex(vert);
			if !polys.has(vert.polygon):
				polys.append(vert.polygon);
		for poly: Polygon in polys:
			poly.update_polygon();
		for obj in get_tree().get_nodes_in_group(&"selected_objects"):
			obj.queue_free();
		for obj in get_tree().get_nodes_in_group(&"selected_polygons"):
			obj.queue_free();
		deselect_verts();
		deselect_objects();
		selection_changed.emit();

# things that should only run while not hoveringhover gui
# (mostly clicking)
func _unhandled_input(ev: InputEvent):
	if drawing == DrawingMode.NONE:
		if ev.is_action_pressed("editor_click"):
			if tool == Tool.VERT_SELECT:
				if snapped_vert != null:
					if !Input.is_action_pressed("editor_multiselect") && !snapped_vert.selected:
						deselect_verts();
					if !Input.is_action_pressed("editor_multiselect") || !snapped_vert.selected:
						select_vert(snapped_vert);
						drawing = DrawingMode.MOVE_VERT;
					else:
						deselect_vert(snapped_vert);
					selection_changed.emit();
				else:
					if !Input.is_action_pressed("editor_multiselect"): deselect_verts();
					selection_changed.emit();
					select_origin = actual_mp;
					select_rect = Rect2(actual_mp, Vector2.ZERO);
					drawing = DrawingMode.RECT_SELECT;
			elif tool == Tool.LINE:
				drawing_polygon = [EditorLib.create_vertex(mouse_pos)];
				drawing = DrawingMode.LINE;
			elif tool == Tool.OBJECT_PLACE && place_object != null:
				var node: Node2D = EditorLib.create_object(place_object, container);
				node.position = mouse_pos;
				container.objects.add_child(node);
			
			elif tool == Tool.OBJECT_SELECT:
				# select objects
				var clicked_objects: Array[Node] = [];
				for obj in object_detector.get_overlapping_areas():
					if obj is EditorObjectBounds:
						clicked_objects.append(obj);
				
				if drawing != DrawingMode.RECT_SELECT && clicked_objects.size() > 0:
					# always select the frontmost object
					clicked_objects.sort_custom(sort_objects);
					var clicked_object: Node2D = clicked_objects[-1].get_parent();
					
					if !Input.is_action_pressed("editor_multiselect") && !clicked_object.is_in_group(&"selected_objects"):
						deselect_objects();
					if !Input.is_action_pressed("editor_multiselect") || !clicked_object.selected:
						select_object(clicked_object);
						drawing = DrawingMode.MOVE_OBJECT;
						
						# move objects to front
						if !Input.is_action_pressed("editor_multiselect"):
							var selected_objects = get_tree().get_nodes_in_group(&"selected_objects");
							selected_objects.sort_custom(sort_nodes);
							for obj: Node in selected_objects:
								obj.get_parent().move_child(obj, -1);
					else:
						deselect_object(clicked_object);
					selection_changed.emit();
				else:
					if !Input.is_action_pressed("editor_multiselect"): deselect_objects();
					selection_changed.emit();
					ignore_select_objects = get_tree().get_nodes_in_group(&"selected_objects");
					select_origin = actual_mp;
					select_rect = Rect2(actual_mp, Vector2.ZERO);
					drawing = DrawingMode.RECT_SELECT;
			
			elif tool == Tool.POLY_SELECT:
				# select polygons
				var clicked_objects: Array[Polygon] = [];
				for obj in object_detector.get_overlapping_bodies():
					if obj.get_parent() is Polygon:
						clicked_objects.append(obj.get_parent());
				
				if drawing != DrawingMode.RECT_SELECT && clicked_objects.size() > 0:
					# always select the frontmost polygon
					clicked_objects.sort_custom(sort_nodes);
					var clicked_object: Polygon = clicked_objects[-1];
					
					if !Input.is_action_pressed("editor_multiselect") && !clicked_object.is_in_group(&"selected_polygons"):
						deselect_polygons();
					if !Input.is_action_pressed("editor_multiselect") || !clicked_object.selected:
						select_polygon(clicked_object);
						drawing = DrawingMode.MOVE_OBJECT;
						
						# move objects to front
						if !Input.is_action_pressed("editor_multiselect"):
							var selected_objects := get_tree().get_nodes_in_group(&"selected_polygons");
							selected_objects.sort_custom(sort_nodes);
							for obj: Polygon in selected_objects:
								obj.get_parent().move_child(obj, -1);
					else:
						deselect_polygon(clicked_object);
					selection_changed.emit();
				else:
					if !Input.is_action_pressed("editor_multiselect"): deselect_polygons();
					selection_changed.emit();
					ignore_select_objects = get_tree().get_nodes_in_group(&"selected_polygons");
					select_origin = actual_mp;
					select_rect = Rect2(actual_mp, Vector2.ZERO);
					drawing = DrawingMode.RECT_SELECT;
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

func do_object_detector(area: Area2D, exiting: bool):
	if tool != Tool.OBJECT_SELECT || drawing != DrawingMode.RECT_SELECT: return;
	var parent = area.get_parent();
	if !parent || !parent.is_in_group(&"editor_objects"): return;
	if parent in ignore_select_objects: return;
	if exiting:
		parent.remove_from_group(&"selected_objects");
	else:
		parent.add_to_group(&"selected_objects");
	selection_changed.emit();
	area.queue_redraw();

func do_polygon_detector(body: CollisionObject2D, exiting: bool):
	if tool != Tool.POLY_SELECT || drawing != DrawingMode.RECT_SELECT: return;
	var poly: Polygon = body.get_parent();
	if !poly.is_in_group(&"polygons"): return;
	if poly in ignore_select_objects: return;
	if exiting:
		poly.remove_from_group(&"selected_polygons");
	else:
		poly.add_to_group(&"selected_polygons");
	selection_changed.emit();
	poly.redraw();

# utilities
func deselect_verts():
	for vert in selected_verts:
		vert.selected = false;
		if vert.polygon: vert.polygon.redraw();
	selected_verts.clear();
func deselect_vert(vert: Vertex):
	vert.selected = false;
	selected_verts.erase(vert);
	if vert.polygon: vert.polygon.redraw();
func select_vert(vert: Vertex):
	vert.selected = true;
	if !selected_verts.has(vert):
		selected_verts.append(vert);
	if vert.polygon: vert.polygon.redraw();

func sort_nodes(a: Node, b: Node):
	return a.get_index() < b.get_index();
func sort_objects(a: Node, b: Node):
	return a.get_parent().get_index() < b.get_parent().get_index();

func select_object(obj: Node):
	obj.add_to_group(&"selected_objects");
	for child in obj.get_children():
		if child is EditorObjectBounds: child.queue_redraw();
func deselect_object(obj: Node):
	obj.remove_from_group(&"selected_objects");
	for child in obj.get_children():
		if child is EditorObjectBounds: child.queue_redraw();
func deselect_objects():
	for obj in get_tree().get_nodes_in_group(&"selected_objects"):
		deselect_object(obj);
		
func select_polygon(obj: Polygon):
	obj.add_to_group(&"selected_polygons");
	obj.queue_redraw();
func deselect_polygon(obj: Polygon):
	obj.remove_from_group(&"selected_polygons");
	obj.queue_redraw();
func deselect_polygons():
	for obj in get_tree().get_nodes_in_group(&"selected_polygons"):
		deselect_polygon(obj);

# mode switching
func select_tool(t: Tool):
	if tool == t: return;
	
	deselect_verts();
	deselect_objects();
	deselect_polygons();
	selection_changed.emit();
	finish_drawing(true);
	
	place_object = null;
	tool = t;
func select_mode(m: Mode):
	if mode == m: return;
	mode = m;
	place_object = null;

func poly_layer_button():
	var selected_polygons = get_tree().get_nodes_in_group(&"selected_polygons");
	if selected_polygons.size() <= 0: return;
	
	var layer: String = selected_polygons[0].layer;
	for poly: Polygon in selected_polygons:
		if poly.layer != layer:
			layer = "";
	match layer:
		"a": layer = "b";
		"b": layer = "ab";
		_: layer = "a";
	
	for poly in selected_polygons:
		poly.layer = layer;

func line_edge_button():
	if selected_verts.size() <= 0: return;
	
	var edge = selected_verts[0].edge;
	for vert in selected_verts:
		if vert.edge != edge:
			edge = "";
	match edge:
		"auto": edge = "none";
		"none": edge = "auto";
		_: edge = "auto";
	
	var polys: Array[Polygon] = [];
	for vert in selected_verts:
		vert.edge = edge;
		if !(vert.polygon in polys):
			polys.append(vert.polygon);
	for poly in polys:
		poly.update_polygon();

signal selection_changed
