extends Node

## this is where the serialized level is stored between scenes.
var load_level: Dictionary = LevelContainer.empty_level();
var level_path := "";
var level_manager: LevelManager = null;
var coming_from_my_levels := false;

const FOLDER = "user://levels/";

const MUSIC_PATH = "res://music/";
class SongDef:
	var name: String = "Unknown";
	var author: String = "Unknown";
	var as_seen_in: String = "Unknown";
	var path: String;
	
	func _init(_name: String, _author: String, _music_path: String, _as_seen_in: String = "") -> void:
		name = _name;
		author = _author;
		path = MUSIC_PATH + _music_path if _music_path != "" else _music_path;
		as_seen_in = _as_seen_in;

var songs: Dictionary[StringName, SongDef] = {
	none = SongDef.new("Silence", "", "", "None"),
	green_hill_zone = SongDef.new("Green Hill Zone - Sonic the Hedgehog", "SEGA Sound Team", "green_hill_zone.ogg", "Green Hill Zone"),
	takeoff = SongDef.new("Take Off - Knuckles Chaotix", "SEGA Sound Team", "takeoff.ogg", "Title Screen"),
	s3db_menu = SongDef.new("Menu - Sonic 3D Blast", "SEGA Sound Team?", "s3db_menu.ogg", "Level List"),
	blue_ska = SongDef.new("Blue Ska", "Kevin MacLeod", "blue_ska.ogg", "Secret"),
};

# layer ids
const LAYER_A = (1 << 0);
const LAYER_B = (1 << 1);
const LAYER_EDITOR_OBJECTS = (1 << 3);
const LAYER_PLAYER = (1 << 4);
const LAYER_POLYGONS = (1 << 5);
const LAYER_MONITORS = (1 << 6);

# names of layers.
# this is used by LayeredTileset
const LAYER_A_NAME = "Collision A";
const LAYER_B_NAME = "Collision B";

const POP_SCENE := preload("res://objects/enemies/badnik/BadnikPop.tscn");

## Spwans a [BadnikPop].
# unused argument so it can be easily connected
# to the hurt signal (which is the case for most badniks)
func pop(node: Node2D):
	var explosion: BadnikPop = POP_SCENE.instantiate();
	explosion.global_position = node.global_position;
	explosion.play_sound = true;
	var parent := node.get_parent();
	parent.add_child(explosion);
	parent.move_child(explosion, node.get_index() - 1);
