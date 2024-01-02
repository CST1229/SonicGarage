extends Button

@export var target: Monitor;

const ITEMS = [&"ring", &"eggman"];
const SPRITES = preload("res://objects/level/Monitor/items/sprites/monitor_item.tres");

func _ready():
	pressed.connect(_on_pressed);
	update_icon();

func _on_pressed():
	pass

func update_icon():
	icon = SPRITES.get_frame_texture(target.item, 0);
