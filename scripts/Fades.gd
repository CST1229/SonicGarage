## Global object for scene transitions and fades.
extends Node

const SCENE_MANAGER_PATH = "res://scenes/SceneManager/SceneManager.tscn";
const FADE_SCENE = preload("res://objects/ui/Fade/Fade.tscn");
const FADE_DURATION = 0.4;

@onready var fade_container: CanvasLayer = CanvasLayer.new();

var scene_manager_default_scene: String = "res://scenes/Disclaimer/Disclaimer.tscn";
const scene_manager_default_scene_nodisclaimer = "res://scenes/TitleScreen/TitleScreen.tscn";
var is_fading_to_scene: Fade = null;

var scene_manager: SceneManager;
var current_scene: Node:
	get:
		return scene_manager.current_scene if scene_manager else null;

func _ready() -> void:
	if !Settings.show_disclaimer:
		scene_manager_default_scene = scene_manager_default_scene_nodisclaimer;
	
	fade_container.layer = 499;
	add_child(fade_container);
	check_run_current_scene.call_deferred();

func check_run_current_scene():
	create_fade(false, true);
	if get_tree().current_scene.scene_file_path != SCENE_MANAGER_PATH:
		await get_tree().process_frame;
		scene_manager_default_scene = get_tree().current_scene.scene_file_path;
		get_tree().change_scene_to_file(SCENE_MANAGER_PATH);

func fade_to_scene(path: String, extra_options := {}) -> Fade:
	if is_fading_to_scene: return;
	if path != "restart":
		ResourceLoader.load_threaded_request(path);
	var created_fade: Fade = create_fade(true, false, func(fade):
		if extra_options.get("stop_music", true):
			Music.stop();
		if "extra_wait" in extra_options:
			await get_tree().create_timer(extra_options.extra_wait).timeout;
		is_fading_to_scene = null;
		fade.affects_volume = false;
		if path == "restart":
			reload_current_scene();
		else:
			change_scene_to_packed(ResourceLoader.load_threaded_get(path));
		fade.tween = fade_existing(fade, false, true);
	, extra_options.get("is_white", false));
	is_fading_to_scene = created_fade;
	created_fade.affects_volume = extra_options.get("stop_music", true);
	return created_fade;

func create_fade(is_in: bool = false, destroy: bool = false, callback: Callable = Callable(), is_white: bool = false) -> Fade:
	var fade: Fade = FADE_SCENE.instantiate();
	fade.is_white = is_white;
	fade_container.add_child(fade);
	
	fade.tween = fade_existing(fade, is_in, destroy, callback);
	return fade;

func fade_existing(fade: Fade, is_in: bool = false, destroy: bool = false, callback: Callable = Callable()) -> Tween:
	var tween: Tween = fade.create_tween();
	fade.fade = 0.0 if is_in else 1.0;
	fade.process_mode = Node.PROCESS_MODE_PAUSABLE;
	tween.set_trans(Tween.TRANS_SINE);
	tween.tween_property(fade, "fade", 1.0 if is_in else 0.0, FADE_DURATION);
	tween.tween_callback(callback.bind(fade));
	if destroy:
		tween.tween_callback(fade.queue_free);
	return tween;

func change_scene_to_file(path: String) -> Error:
	scene_changed.emit(load(path));
	return OK;

func change_scene_to_packed(scene: PackedScene) -> Error:
	scene_changed.emit(scene);
	return OK;

func reload_current_scene() -> Error:
	scene_changed.emit(load(current_scene.scene_file_path));
	return OK;

signal scene_changed(scene: PackedScene);
