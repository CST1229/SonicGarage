## An item that pops up from a [Monitor].
extends AnimatedSprite2D
class_name MonitorItem

var popped := false;
var pop_timer: float = 0.0;
var reward_given := false;

var popped_player: Player;

var container: LevelContainer;

const SPRITE_FRAMES = preload("res://objects/level/Monitor/items/sprites/monitor_item.tres");

const POP_TIME = 1.25;

func _enter_tree():
	sprite_frames = SPRITE_FRAMES;

func _process(delta: float):
	if container && container.editor_mode:
		frame = 0;
		speed_scale = 0;
		return;
	
	if popped:
		pop_timer += delta;
		offset.y = ease(clampf(pop_timer * POP_TIME, 0, 1), 0.25) * -32;
		if pop_timer >= (POP_TIME / 2.0) && !reward_given:
			_give_reward(popped_player);
			reward_given = true;
		if pop_timer >= POP_TIME:
			queue_free();

func pop(player: Player):
	popped_player = player;
	popped = true;
	speed_scale = 0;
	frame = 0;
	frame_progress = 0;

func _give_reward(_player: Player):
	pass
