# music and other sound stuff
extends Node

var player := AudioStreamPlayer.new();

var volume: float = 1.0:
	get:
		return volume;
	set(value):
		volume = value;
		var player_volume := volume * fade_volume;
		if is_in_editor():
			player_volume *= EDITOR_VOLUME_MULTIPLIER;
		player.volume_linear = player_volume;
var position: float:
	get:
		return player.get_playback_position();
	set(value):
		player.seek(value);

var fade_volume: float = 1.0:
	set(value):
		fade_volume = value;
		volume = volume;
const EDITOR_VOLUME_MULTIPLIER = 1.0;

var focus_volume: float = 1.0;
const FOCUS_VOLUME_SPEED = 1.0 / 0.2;

var current_song := "";

func _ready():
	focus_volume = 0 if should_focus_mute() else 1;
	update_audio();
	
	player.bus = &"Music";
	add_child(player);
	Fades.scene_changed.connect.call_deferred(_on_scene_changed);

func _process(delta: float) -> void:
	focus_volume = move_toward(focus_volume, 0 if should_focus_mute() else 1, FOCUS_VOLUME_SPEED * delta);
	update_audio();

func update_audio() -> void:
	set_bus_volume(&"Master", Settings.master_volume * focus_volume);
	set_bus_volume(&"Music", Settings.music_volume);
	set_bus_volume(&"SFX", Settings.sfx_volume);
	var music_bus := AudioServer.get_bus_index(&"Music");
	AudioServer.set_bus_effect_enabled(music_bus, 0, is_in_editor());
	
func should_focus_mute() -> bool:
	return Settings.mute_on_focus_lost && !DisplayServer.window_is_focused();

func set_bus_volume(bus_name: StringName, new_volume: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name);
	AudioServer.set_bus_volume_linear(bus, new_volume);

func play(song: AudioStream):
	if current_song != song.resource_path:
		current_song = song.resource_path;
		player.stream = song;
		player.play();

func restart():
	if player.has_stream_playback():
		player.play();

func stop():
	player.stop();
	current_song = "";

func is_in_editor():
	if Fades.current_scene is not EditorRoom:
		return false;
	var scene := Fades.current_scene as EditorRoom;
	return scene.level_container && scene.level_container.editor_mode;

func _on_scene_changed(_scene: PackedScene) -> void:
	# update volume for editor
	fade_volume = 1.0;
	volume = volume;
	update_audio();
