extends Node2D

@onready var sprite = $Sprite2D;
var container: LevelContainer;
var is_ghost := false;

var flip_h := false:
	set(value):
		flip_h = value;
		if sprite:
			sprite.scale.x = -1 if flip_h else 1;

func _enter_tree():
	if container:
		container.player_start_pos = position;
		if !container.editor_mode:
			queue_free();

func _ready():
	flip_h = flip_h;
	for obj in get_tree().get_nodes_in_group(&"player_start"):
		if obj != self && !obj.is_ghost:
			# prevent them from showing the player ghost
			obj.is_ghost = true;
			obj.queue_free();
	if !is_ghost && container.editor && container.editor.player_ghost:
		container.editor.player_ghost.visible = false;

func _exit_tree():
	if !is_ghost && container.editor && container.editor.player_ghost:
		container.editor.player_ghost.visible = true;

func serialize() -> Dictionary:
	return {
		x = position.x,
		y = position.y,
		flip_h = flip_h,
	};
func deserialize(json: Dictionary) -> void:
	position.x = json.x;
	position.y = json.y;
	flip_h = json.flip_h;
