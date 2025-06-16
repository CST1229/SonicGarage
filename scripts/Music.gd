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
const EDITOR_VOLUME_MULTIPLIER = 0.5;

var current_song := "";

func _ready():
	player.bus = &"Music";
	add_child(player);
	Fades.scene_changed.connect.call_deferred(_on_scene_changed);

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
