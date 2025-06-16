class_name SceneManager
extends Node2D

var current_scene: Node;

func _ready() -> void:
	Fades.scene_manager = self;
	change_scene_to_packed(Fades.scene_manager_default_scene);
	Fades.scene_changed.connect(change_scene_to_packed);

func change_scene_to_file(path: String) -> Error:
	change_scene_to_packed(load(path));
	return OK;

func change_scene_to_packed(scene: PackedScene) -> Error:
	if current_scene:
		current_scene.queue_free();
	current_scene = scene.instantiate();
	add_child(current_scene);
	return OK;
