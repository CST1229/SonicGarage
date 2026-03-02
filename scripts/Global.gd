## global stuff and utilities
extends Node

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

class ObjectDef:
	var scene: String;
	var name: String;
	var icon_path: String;
func obj(ui_name: String, scene: String, icon_path: String = "res://objects/editor/empty_object_icon.png"):
	var def = ObjectDef.new();
	def.name = ui_name;
	def.scene = scene;
	def.icon_path = icon_path;
	return def;

## The list of objects (used by deserialization).
var object_list: Dictionary = {
	layer_switcher = obj(
		"Layer Switcher", "res://objects/level/LayerSwitcher/LayerSwitcher.tscn",
		"res://objects/level/LayerSwitcher/icon.png"
	),
	ring = obj(
		"Ring", "res://objects/level/Ring/Ring.tscn",
		"res://objects/level/Ring/sprites/ring1.png"
	),
	signpost = obj(
		"Signpost", "res://objects/level/Signpost/Signpost.tscn",
		"res://objects/level/Signpost/icon.png"
	),
	motobug = obj(
		"Motobug", "res://objects/enemies/Motobug/Motobug.tscn",
		"res://objects/enemies/Motobug/icon.png"
	),
	monitor = obj(
		"Item Monitor", "res://objects/level/Monitor/Monitor.tscn",
		"res://objects/level/Monitor/icon.png"
	),
	spike = obj(
		"Spikes", "res://objects/level/Spike/Spike.tscn",
		"res://objects/level/Spike/sprites/spikes.png"
	),
	spring = obj(
		"Spring", "res://objects/level/Spring/Spring.tscn",
		"res://objects/level/Spring/icon.png"
	),
	player_start = obj(
		"Player Start", "res://objects/level/PlayerStart/PlayerStart.tscn",
		"res://objects/level/PlayerStart/icon.png"
	),
	bumper = obj(
		"Bumper", "res://objects/level/Bumper/Bumper.tscn",
		"res://objects/level/Bumper/sprites/idle.png"
	),
};
## A list of object IDs that are visible in the editor.
var editor_object_list: Array[String] = [
	"player_start",
	"ring",
	"layer_switcher",
	"signpost",
	"motobug",
	"monitor",
	"spike",
	"spring",
	"bumper",
];
var object_paths_to_id: Dictionary[String, String] = {};

var songs: Dictionary[StringName, SongDef] = {
	none = SongDef.new("Silence", "", "", "None"),
	green_hill_zone = SongDef.new("Green Hill Zone - Sonic the Hedgehog", "SEGA Sound Team", "green_hill_zone.ogg", "Green Hill Zone"),
	takeoff = SongDef.new("Take Off - Knuckles Chaotix", "SEGA Sound Team", "takeoff.ogg", "Title Screen"),
	s3db_menu = SongDef.new("Menu - Sonic 3D Blast", "SEGA Sound Team?", "s3db_menu.ogg", "Level List"),
	blue_ska = SongDef.new("Blue Ska", "Kevin MacLeod", "blue_ska.ogg", "Secret"),
};

var level_themes: Dictionary[StringName, String] = {
	green_hill = "res://sprites/level_themes/GreenHill/theme_def.tres",
	emerald_hill = "res://sprites/level_themes/EmeraldHill/theme_def.tres",
	marble = "res://sprites/level_themes/Marble/theme_def.tres",
};


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS;
	update_object_paths_to_id();

func update_object_paths_to_id() -> void:
	for i in object_list.keys():
		object_paths_to_id[object_list[i].scene] = i;

const UI_THEME: Theme = preload("res://sprites/ui/ui_theme.tres");

# reactive-ish objects

# a linked signal connection is deleted when either of the objects it is linked to is also deleted
var connection_links: Array[ConnectionLink] = [];
class ConnectionLink:
	static func garbage_collect() -> void:
		for i in range(Global.connection_links.size() - 1, -1, -1):
			var link: ConnectionLink = Global.connection_links[i];
			if !is_instance_valid(link.link_to.get_ref()) || !is_instance_valid(link.linked.get_ref()):
				if is_instance_valid(link.linked_signal.get_object()):
					link.linked_signal.disconnect(link.linked_callable);
				Global.connection_links.remove_at(i);
	static func add(_linked: Object, _linked_signal: Signal, _linked_callable: Callable, _link_to: Object) -> void:
		var link := new();
		link.linked = weakref(_linked);
		link.linked_signal = _linked_signal;
		link.linked_callable = _linked_callable;
		link.link_to = weakref(_link_to);
		Global.connection_links.append(link);
	static func add_and_connect(_linked: Object, _linked_signal: Signal, _linked_callable: Callable, _link_to: Object) -> void:
		_linked_signal.connect(_linked_callable);
		add(_linked, _linked_signal, _linked_callable, _link_to);
	
	var linked: WeakRef;
	var linked_signal: Signal;
	var linked_callable: Callable;
	var link_to: WeakRef;

func _physics_process(_delta: float) -> void:
	ConnectionLink.garbage_collect();

static var CALLABLE_IDENTITY = func(value: Variant) -> Variant:
	return value;

func binding(source: Object, source_property: StringName, source_changed: Signal, target: Object, target_property: StringName, target_changed: Signal, map_source_to_target: Callable = CALLABLE_IDENTITY, map_target_to_source: Callable = CALLABLE_IDENTITY):
	target.set(target_property, map_source_to_target.call(source.get(source_property)));
	ConnectionLink.add_and_connect(source, source_changed, func(value: Variant):
		if !target || !source:
			return;
		var mapped_value = map_source_to_target.call(value);
		if mapped_value != target.get(target_property):
			target.set(target_property, mapped_value);
	, target);
	ConnectionLink.add_and_connect(target, target_changed, func(value: Variant):
		if !target || !source:
			return;
		var mapped_value = map_target_to_source.call(value);
		if mapped_value != source.get(source_property):
			source.set(source_property, mapped_value);
	, source);
	
# for cases where the source's "property changed" signal is one signal with a StringName argument for which property changed
func wildcard_binding(source: Node, source_property: StringName, source_changed: Signal, target: Node, target_property: StringName, target_changed: Signal, map_source_to_target: Callable = CALLABLE_IDENTITY, map_target_to_source: Callable = CALLABLE_IDENTITY):
	target.set(target_property, map_source_to_target.call(source.get(source_property)));
	ConnectionLink.add_and_connect(source, source_changed, func(prop: StringName):
		if prop != source_property:
			return;
		if !target || !source:
			return;
		var new_value = map_source_to_target.call(source.get(source_property));
		if new_value != target.get(target_property):
			target.set(target_property, new_value);
	, target);
	ConnectionLink.add_and_connect(target, target_changed, func(value: Variant):
		if !target || !source:
			return;
		var mapped_value = map_target_to_source.call(value);
		if mapped_value != source.get(source_property):
			source.set(source_property, mapped_value);
	, source);

# bind specifically a setting
func setting_binding(setting: StringName, target: Node, target_property: StringName, target_changed: Signal, map_setting_to_target: Callable = CALLABLE_IDENTITY, map_target_to_setting: Callable = CALLABLE_IDENTITY):
	wildcard_binding(Settings, setting, Settings.changed, target, target_property, target_changed, map_setting_to_target, map_target_to_setting);
