extends Node

@onready var container: VBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer;
@onready var current_dir_label: Label = $CurrentDir;

var current_dir: String:
	set(value):
		current_dir = value;
		if !current_dir.ends_with("/"):
			current_dir += "/";
		current_dir_label.text = current_dir.replace("user://", "");
		reload();
		focus_file = "";
var focus_file: String = "";

var first_item: Button = null;
var last_item: Button = null;

var create_level_button: Button = null;
var create_folder_button: Button = null;

const ITEM_HEIGHT = 16;

const INVALID_FILENAME_CHARS = ['"', "\\", "/", ":", "*", "?", "<", ">", "|"]

func _ready():
	Music.play(preload("res://music/s3db_menu.mp3"));
	DirAccess.make_dir_recursive_absolute(current_dir);
	current_dir = LevelUtil.FOLDER;
	if LevelUtil.level_path.begins_with(LevelUtil.FOLDER):
		current_dir = LevelUtil.level_path.get_base_dir();
		focus_file = LevelUtil.level_path.get_file()
		LevelUtil.level_path = "";

func reload():
	for node in container.get_children():
		node.queue_free();
	first_item = null;
	last_item = null;
	
	var prev := add_item("← Back");
	prev.pressed.connect(func():
		focus_file = current_dir.trim_suffix("/").get_file();
		go_back();
	);
	
	first_item.grab_focus();
	var dir := DirAccess.open(current_dir);
	if !dir:
		var error_padding := Control.new();
		error_padding.custom_minimum_size.y = 4;
		container.add_child(error_padding);
		
		var error := Label.new();
		error.text = "Error opening directory: " + error_string(DirAccess.get_open_error());
		container.add_child(error);
		return;
	
	var create_arr := add_text_edit_item("Create Level...", "Enter name...", "+", func(value: String):
		value = value.strip_edges();
		if value == "":
			return;
		value = value + ".sgl";
		for invalid_char in INVALID_FILENAME_CHARS:
			if value.contains(invalid_char):
				create_folder_button.text = "+ Name can't contain " + "".join(INVALID_FILENAME_CHARS);
				return;
		var full_path := current_dir.path_join(value);
		if FileAccess.file_exists(full_path):
			create_folder_button.text = "+ Level already exists";
			return;
		
		var dict := LevelContainer.empty_level();
		var err := EditorLib.save_level_static(dict, full_path);
		if err:
			create_folder_button.text = "+ Error: " + error_string(err);
			return;
		
		reload();
		create_level_button.grab_focus();
	);
	create_level_button = create_arr[0];
	var create_folder_arr := add_text_edit_item("Create Folder...", "Enter name...", "📁+", func(value: String):
		value = value.strip_edges();
		if value == "":
			return;
		for invalid_char in INVALID_FILENAME_CHARS:
			if value.contains(invalid_char):
				create_folder_button.text = "📁+ Name can't contain " + "".join(INVALID_FILENAME_CHARS);
				return;
		var error := dir.make_dir_recursive(current_dir.path_join(value));
		if error != OK:
			create_folder_button.text = "📁+ Error: " + error_string(error);
			return;
		reload();
		create_folder_button.grab_focus();
	);
	create_folder_button = create_folder_arr[0];
	
	if current_dir != LevelUtil.FOLDER:
		var del_folder := add_item("📁X Delete Folder");
		del_folder.pressed.connect(func():
			var check_files := dir.get_files();
			if !check_files.is_empty():
				del_folder.text = "📁X Directory must be empty.";
				return;
			dir.remove(".");
			go_back();
		);
	
	
	var padding := Control.new();
	padding.custom_minimum_size.y = 4;
	container.add_child(padding);
	
	var has_levels := false;
	var dirs := dir.get_directories();
	for dir_name in dirs:
		has_levels = true;
		var dir_item := add_item("📁 " + dir_name);
		dir_item.pressed.connect(func():
			current_dir = current_dir.path_join(dir_name);
		);
		if dir_name == focus_file:
			dir_item.grab_focus();
	var files := dir.get_files();
	for level_name in files:
		if !level_name.to_lower().ends_with(".sgl"):
			continue;
		has_levels = true;
		var level_item := add_item(level_name.get_basename());
		level_item.pressed.connect(func():
			LevelUtil.coming_from_my_levels = true;
			var full_path := current_dir.path_join(level_name);
			EditorLib.load_level(true, full_path, true);
		);
		if level_name == focus_file:
			level_item.grab_focus();
	
	if !has_levels:
		var note := Label.new();
		note.text = "No levels here. Create some!";
		note.self_modulate = Color(0.5, 0.5, 0.5);
		container.add_child(note);
	
	last_item.focus_neighbor_bottom = first_item.get_path();
	first_item.focus_neighbor_top = last_item.get_path();

func go_back():
	if current_dir != LevelUtil.FOLDER:
		current_dir = current_dir.path_join("..").simplify_path()
	else:
		Fades.fade_to_scene("res://scenes/TitleScreen/TitleScreen.tscn");

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("editor_quit"):
		get_viewport().set_input_as_handled();
		go_back();

# on_submit takes in a String
# on_edit, if passed, should return a string (which becomes the default value for the textbox)
# returns: [Button, LineEdit, Control (container)]
func add_text_edit_item(item_name: String, placeholder: String, text_icon: String = "", on_submit: Callable = Callable(), on_edit: Callable = Callable()) -> Array:
	var full_item_name := item_name;
	if text_icon != "":
		full_item_name = text_icon + " " + item_name;
	var button := add_item(full_item_name);
	var textbox_container := Control.new();
	textbox_container.custom_minimum_size.y = ITEM_HEIGHT;
	textbox_container.visible = false;
	
	var textbox := LineEdit.new();
	textbox.set_anchors_preset(Control.PRESET_FULL_RECT);
	textbox.offset_top = -3;
	textbox.offset_bottom = -3;
	textbox.theme_type_variation = &"LevelsListButton";
	textbox.visible = true;
	textbox.max_length = 64;
	var icon: Label;
	if text_icon != "":
		icon = Label.new();
		icon.text = text_icon + " ";
		icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN;
		icon.offset_top = 1;
		textbox_container.add_child(icon);
	
	textbox.caret_blink = true;
	do_focus_yellowing(textbox);
	if icon:
		do_focus_yellowing(textbox, icon);
	textbox.gui_input.connect(func(ev: InputEvent):
		if ev is not InputEventKey:
			return;
		var key_ev := ev as InputEventKey;
		if key_ev.keycode == KEY_ESCAPE && key_ev.pressed:
			button.grab_focus();
	);
	textbox.focus_entered.connect(func():
		button.text = full_item_name;
		if icon:
			textbox.offset_left = icon.get_rect().size.x;
	);
	textbox.focus_exited.connect(func():
		textbox_container.visible = false;
		button.visible = true;
	);
	textbox.placeholder_text = placeholder;
	textbox.text_submitted.connect(func(value: String):
		button.grab_focus();
		on_submit.call(value);
	);
	textbox_container.add_child(textbox);
	container.add_child(textbox_container);
	
	button.pressed.connect(func():
		textbox_container.visible = true;
		button.visible = false;
		if !on_edit.is_valid():
			textbox.text = "";
		else:
			textbox.text = str(on_edit.call());
		textbox.grab_focus();
	);
	return [button, textbox];

func add_item(item_name: String) -> Button:
	var level := Button.new();
	level.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;
	level.theme_type_variation = &"LevelsListButton";
	level.text = item_name;
	level.custom_minimum_size.y = ITEM_HEIGHT;
	level.alignment = HORIZONTAL_ALIGNMENT_LEFT;
	level.clip_text = true;
	level.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS;
	do_focus_yellowing(level);
	container.add_child(level);
	if !first_item:
		first_item = level;
	last_item = level;
	return level;

func do_focus_yellowing(control: Control, for_control: Control = control):
	control.focus_entered.connect(func():
		for_control.self_modulate = Color.YELLOW;
	);
	control.focus_exited.connect(func():
		for_control.self_modulate = Color.WHITE;
	);
