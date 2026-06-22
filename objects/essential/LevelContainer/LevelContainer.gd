## The main container for a level.
##
## A LevelContainer contains the level ([Polygon]s and objects).
## It also handles serializing and deserializing the level
## and acts as a link between objects and the [LevelEditor].
@tool
extends Node
class_name LevelContainer

@export var editor_mode := false;
@export var editor: LevelEditor = null;
@export var music: String = "green_hill_zone";
@export var theme_id: String:
	set(value):
		theme_id = value;
		if theme_id not in Global.level_themes:
			theme_id = "green_hill";
		theme = load(load(Global.level_themes[theme_id]).theme_file);
var theme: LevelTheme = null;
@export var show_background := true;

var dirty: bool = true;

@onready var bg_color: ColorRect = $BackgroundColor/BGColor
@onready var background_container: Control = $Background/BackgroundContainer
@onready var polygons: Node2D = $polygons;
@onready var objects: Node2D = $objects;
@onready var players: Node2D = $players;
var player: Player;

var player_start_pos := Vector2(0, 0);

const FORMAT_VERSION = 2;

var POLYGON_SCENE = load("res://objects/essential/LevelContainer/Polygon.tscn");
var PLAYER_SCENE = load("res://objects/essential/Player/Player.tscn");

func _ready():
	if editor_mode:
		objects.process_mode = Node.PROCESS_MODE_DISABLED;
		background_container.modulate.a8 = 68;
		bg_color.modulate = background_container.modulate;
	bg_color.visible = show_background;
	background_container.visible = show_background;

func deserialize(level: Dictionary) -> String:
	if !(level is Dictionary):
		return "Invalid level (not a dictionary)";
		
	if !("format" in level):
		if "polygons" in level && level["polygons"] is Array:
			# Old, old level
			level.format = 1;
		else:
			return "Invalid level (missing objects/polygons key or format version)";
	
	if level.format > FORMAT_VERSION:
		return "Level is too new! Has format version: {0} (current is {1})".format([level.format, FORMAT_VERSION])
	
	if "theme" in level:
		theme_id = str(level.theme);
	else:
		theme_id = "green_hill";
	
	if "music" in level:
		music = str(level.music);
	else:
		music = "green_hill_zone";
	deserialize_polygons(level.get("polygons", []));
	deserialize_objects(level.get("objects", []));
	add_players();
	
	return "";

func deserialize_polygons(polys: Array) -> void:
	for node in polygons.get_children():
		node.queue_free();
	for level_poly in polys:
		var poly = POLYGON_SCENE.instantiate();
		poly.container = self;
		for json_vert in level_poly.vertices:
			var vert;
			if json_vert is Array:
				vert = EditorLib.create_vertex(Vector2(json_vert[0], json_vert[1]));
			else:
				vert = EditorLib.create_vertex(Vector2(json_vert.x, json_vert.y));
				vert.edge = json_vert.edge;
			poly.vertices.append(vert);
			vert.polygon = poly;
		if "layer" in level_poly:
			poly.layer = level_poly.layer;
		if "semisolid" in level_poly:
			poly.semisolid = level_poly.semisolid;
		polygons.add_child(poly);

func deserialize_objects(objs: Array) -> void:
	player_start_pos = Vector2(0, 0);
	for node in objects.get_children():
		node.queue_free();
	for obj_def in objs:
		var node = EditorLib.create_object(obj_def.id, self);
		if !node: continue;
		node.deserialize(obj_def);
		objects.add_child(node);

func add_players() -> void:
	for node in players.get_children():
		node.queue_free();
	if !editor_mode:
		var added_player: Player = PLAYER_SCENE.instantiate();
		if LevelUtil.load_params.is_playtesting_from_pos:
			added_player.position = LevelUtil.load_params.playtest_pos;
		else:
			added_player.position = player_start_pos;
		players.add_child(added_player);
		player = added_player;

static func empty_level() -> Dictionary:
	return {format = FORMAT_VERSION};

func play_music() -> void:
	Music.play_id(music);

func update_theme() -> void:
	for poly: Polygon in get_tree().get_nodes_in_group(&"polygons"):
		poly.update_polygon();

func serialize() -> Dictionary:
	var data := empty_level();
	data.theme = theme_id;
	data.music = music;
	data.polygons = [];
	data.objects = [];
	
	for poly in polygons.get_children():
		var verts_arr: Array[Dictionary] = [];
		for vert in poly.vertices:
			verts_arr.append({
				x = vert.global_position.x,
				y = vert.global_position.y,
				edge = vert.edge,
			});
		data.polygons.append({
			vertices = verts_arr,
			layer = poly.layer,
			semisolid = poly.semisolid,
		});
	
	for obj in objects.get_children():
		if obj.has_method("serialize"):
			var obj_id: String = Global.object_paths_to_id.get(obj.scene_file_path, "");
			assert(obj_id != "", "Level object is not a scene or is not in Global.object_list or Global.object_paths_to_id. Scene file path: " + obj.scene_file_path);
			var serialized: Dictionary = obj.serialize();
			serialized.id = obj_id;
			data.objects.append(serialized);
	
	return data;
