extends Node

# utility functions used by the editor

func create_vertex(pos: Vector2) -> Vertex:
	var vert := Vertex.new();
	vert.position = pos;
	return vert;

func delete_vertex(vert: Vertex):
	if !vert.polygon: return;
	vert.polygon.vertices.erase(vert);
	if vert.polygon.vertices.size() < 3:
		vert.polygon.queue_free();

func create_object(id: String, container: LevelContainer = null) -> Node2D:
	if !(id in Global.object_list):
		return null;
	var obj: Global.ObjectDef = Global.object_list[id];
	var node: Node2D = obj.scene.instantiate();
	if container && container.editor_mode: node.add_to_group(&"editor_objects");
	if container && "container" in node: node.container = container;
	return node;

const VERT_COLOR = Color("#639bff");
const VERT_OUTLINE_COLOR = Color("ffffff");

func draw_vert(to: CanvasItem, pos: Vector2, alpha: float = 1, selected: bool = false):
	var blend := Color(1, 1, 1, alpha);
	var radius := 4.0 if !selected else 6.0;
	to.draw_circle(pos, radius + 1, VERT_OUTLINE_COLOR * blend);
	to.draw_circle(pos, radius, VERT_COLOR * blend);

func save_level(status: bool, selected_paths: PackedStringArray, selected_filter_index: int):
	if !status: return;
	if selected_paths.size() < 1: return;
	var path = selected_paths[0];
	
	if selected_filter_index == 1:
		# Add file extension
		if !(path.to_lower().ends_with(".sgl")):
			path += ".sgl";
	
	var file = FileAccess.open(path, FileAccess.WRITE);
	if file == null:
		OS.alert(error_string(FileAccess.get_open_error()), "Error saving level!");
		return;
	file.store_string(JSON.stringify(Global.load_level));

func load_level_editor(status: bool, selected_paths: PackedStringArray, _selected_filter_index: int):
	_load_level(true, status, selected_paths, _selected_filter_index);

func load_level_play(status: bool, selected_paths: PackedStringArray, _selected_filter_index: int):
	_load_level(false, status, selected_paths, _selected_filter_index);

func _load_level(editor: bool, status: bool, selected_paths: PackedStringArray, _selected_filter_index: int):
	if !status: return;
	if selected_paths.size() < 1: return;
	var path = selected_paths[0];
	
	var file = FileAccess.get_file_as_string(path);
	if file == null:
		OS.alert(error_string(FileAccess.get_open_error()), "Error loading level!");
		return;
	
	var parser = JSON.new();
	
	var err = parser.parse(file);
	if err != Error.OK:
		OS.alert(
			"{0}\nat line {1}".format([parser.get_error_message(), parser.get_error_line()]),
			"Error loading level!"
		);
		return;
	var json = parser.data;
	Global.load_level = json;
	
	if editor:
		get_tree().change_scene_to_file("res://scenes/EditorRoom/EditorRoom.tscn");
	else:
		get_tree().change_scene_to_file("res://scenes/CustomLevel/CustomLevel.tscn");
