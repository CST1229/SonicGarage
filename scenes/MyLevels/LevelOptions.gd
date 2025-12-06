extends Control

@onready var container: GridContainer = $Container
@onready var play: Button = $Container/Play;
@onready var edit: Button = $Container/Edit;
@onready var rename: Button = $Container/Rename;
@onready var duplicate_btn: Button = $Container/Duplicate;
@onready var move: Button = $Container/Move;
@onready var delete: Button = $Container/Delete;

@onready var buttons: Array[Button] = Array(container.get_children(), TYPE_OBJECT, &"Button", null);

var exiting := false;

func _ready():
	clip_contents = true;
	size = container.size;
	size.y = 0;
	
	var tween := create_tween();
	tween.tween_property(self, "size", container.size, 0.1);
	tween.tween_callback(func():
		clip_contents = false;
	);
	duplicate_btn.grab_focus(); # make sure it's visible
	play.grab_focus();
	
	for btn in buttons:
		btn.focus_exited.connect(func():
			if exiting: return;
			await get_tree().process_frame;
			for btn2 in buttons:
				if btn2.has_focus(): return;
			exit();
		);

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") && !exiting:
		exit();

func exit():
	exiting = true;
	var tween := create_tween();
	clip_contents = true;
	tween.tween_property(self, "size", Vector2(container.size.x, 0), 0.1);
	tween.tween_callback(queue_free);
	for child in container.get_children():
		if child is Button:
			(child as Button).mouse_filter = Control.MOUSE_FILTER_IGNORE;
			(child as Button).focus_mode = Control.FOCUS_NONE;
	exited.emit();

signal exited
