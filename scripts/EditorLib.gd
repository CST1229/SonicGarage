## Utility functions used by the editor.
extends Node

## Creates a Vertex object with a position.
func create_vertex(pos: Vector2) -> Vertex:
	var vert := Vertex.new();
	vert.position = pos;
	return vert;

## Properly removes a Vertex object.
func delete_vertex(vert: Vertex):
	if !vert.polygon: return;
	vert.polygon.vertices.erase(vert);
	if vert.polygon.vertices.size() < 3:
		vert.polygon.queue_free();

## Creates an object from an object ID.
func create_object(id: String, container: LevelContainer = null) -> Node2D:
	if !(id in Global.object_list):
		return null;
	var obj: Global.ObjectDef = Global.object_list[id];
	var node: Node2D = load(obj.scene).instantiate();
	if container && container.editor_mode: node.add_to_group(&"editor_objects");
	if container && "container" in node: node.container = container;
	return node;

## The fill color of vertices.
## epic CST color yay
const VERT_COLOR = Color("#639bff");
## The outline color of vertices.
const VERT_OUTLINE_COLOR = Color("ffffff");

## Draws a vertex at a certain position.
func draw_vert(to: CanvasItem, pos: Vector2, alpha: float = 1, selected: bool = false):
	var blend := Color(1, 1, 1, alpha);
	var radius := 4.0 if !selected else 6.0;
	to.draw_circle(pos, radius + 1, VERT_OUTLINE_COLOR * blend);
	to.draw_circle(pos, radius, VERT_COLOR * blend);

## Saves a level to a path and affects level_path. Returns an Error.
func save_level(dict: Dictionary, path: String) -> Error:
	var err := save_level_static(dict, path)
	if !err:
		LevelUtil.level_path = path;
	else:
		OS.alert(error_string(err), "Error saving level!");
	return err;

## Saves a level to a path. Returns an Error.
func save_level_static(dict: Dictionary, path: String) -> Error:		
	var file := FileAccess.open(path, FileAccess.WRITE);
	if file == null:
		return FileAccess.get_open_error();
	file.store_string(JSON.stringify(dict));
	return OK;

## Loads a level.
func load_level(editor: bool, path: String, fade: bool = false) -> Error:
	var file := FileAccess.get_file_as_string(path);
	var err := FileAccess.get_open_error();
	if err:
		OS.alert(error_string(err), "Error loading level!");
		return err;
	
	var parser := JSON.new();
	err = parser.parse(file);
	if err:
		OS.alert(
			"{0}\nat line {1}".format([parser.get_error_message(), parser.get_error_line()]),
			"Error loading level!"
		);
		return err;
	var json = parser.data;
	LevelUtil.load_level = json;
	
	if editor:
		LevelUtil.level_path = path;
		if fade:
			Fades.fade_to_scene("res://scenes/EditorRoom/EditorRoom.tscn");
		else:
			Fades.change_scene_to_file("res://scenes/EditorRoom/EditorRoom.tscn");
	else:
		LevelUtil.level_path = "";
		if fade:
			Fades.fade_to_scene("res://scenes/CustomLevel/CustomLevel.tscn");
		else:
			Fades.change_scene_to_file("res://scenes/CustomLevel/CustomLevel.tscn");
	return OK;
