class_name DancingLogo
extends Control

@export var logo: BaseButton;
@export var ghost_logo: TextureRect;

var clicks := 0;

var positions := PackedVector2Array([Vector2.ZERO]);
var vanilla_positions: PackedVector2Array;

var current_position := Vector2.ZERO:
	set(value):
		current_position = value;
		logo.offset_left = current_position.x + LOGO_X_OFFSET;
		logo.offset_top = current_position.y;
var mouse_offset := Vector2.ZERO;

var recording := false:
	set(value):
		recording = value;
		ghost_logo.visible = recording;
var recording_begun := false;
var last_recorded_time := 0.0;

const SONG_BEGIN = 0.6;
const FRAME = 1.0 / 60.0;
# center the logo on the x axis
const LOGO_X_OFFSET = -79;
const VANILLA_MOVEMENTS_PATH = "res://scenes/TitleScreen/DancingLogo/logo_movements.tres";
const OLD_MOVEMENTS_PATH = "res://scenes/TitleScreen/DancingLogo/logo_movements.bin";
const CUSTOM_MOVEMENTS_PATH = "user://logo_movements.bin";

func _ready() -> void:
	vanilla_positions = preload(VANILLA_MOVEMENTS_PATH).positions;
	if !read_logo_movements(CUSTOM_MOVEMENTS_PATH, positions):
		positions = vanilla_positions.duplicate();
	logo.pressed.connect(func():
		clicks += 1;
		if clicks == 100:
			%NotCopyright.show();
		);
	logo.pressed.connect(_on_click_logo);
	current_position = Vector2.ZERO;
	ghost_logo.offset_left = LOGO_X_OFFSET;

func _process(_delta: float) -> void:
	if recording:
		if Input.is_action_just_pressed(&"editor_cancel") || Input.is_action_just_pressed(&"editor_quit") || Input.is_action_just_pressed(&"ui_cancel"):
			_on_click_logo();
		elif Music.position >= SONG_BEGIN:
			if !recording_begun:
				mouse_offset = get_local_mouse_position();
				recording_begun = true;
			var mouse_pos := get_local_mouse_position() - mouse_offset;
			while Music.position >= (last_recorded_time + FRAME):
				positions.append(mouse_pos);
				last_recorded_time += FRAME;
				current_position = mouse_pos;
			if Music.position < last_recorded_time:
				# music looped, time to save
				recording = false;
				write_logo_movements(CUSTOM_MOVEMENTS_PATH, positions);
	else:
		recording_begun = false;
		var position_index: float = (Music.position - SONG_BEGIN) / FRAME;
		if position_index < 0:
			current_position = Vector2.ZERO;
		else:
			var length := positions.size();
			if length > 0:
				var low_position := positions[fmod(floorf(position_index), length)];
				var high_position := positions[fmod(ceilf(position_index), length)];
				var blend := fmod(position_index, 1);
				current_position = low_position.lerp(high_position, blend);
			last_recorded_time = Music.position;

static func read_logo_movements(path: String, to: PackedVector2Array) -> bool:
	if !FileAccess.file_exists(path):
		return false;
	var file := FileAccess.open(path, FileAccess.READ);
	to.clear();
	while !file.eof_reached():
		var x := file.get_half();
		if !file.eof_reached():
			var y := file.get_half();
			to.append(Vector2(x, y));
	if to.size() == 0:
		to.append(Vector2.ZERO);
	return true;

static func write_logo_movements(path: String, from: PackedVector2Array) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE);
	for vector in from:
		file.store_half(vector.x);
		file.store_half(vector.y);

func _on_click_logo() -> void:
	if OS.has_feature("editor"):
		show_save_vanilla_logo_option.emit();
	if !recording:
		start_recording();
	else:
		cancel_recording();
	Music.restart();

func start_recording() -> void:
	recording_begun = false;
	if !recording:
		recording = true;
		current_position = Vector2.ZERO;
		last_recorded_time = SONG_BEGIN - FRAME;
		positions = PackedVector2Array();

func cancel_recording() -> void:
	recording_begun = false;
	if recording:
		recording = false;
		positions = vanilla_positions.duplicate();
		if FileAccess.file_exists(CUSTOM_MOVEMENTS_PATH):
			DirAccess.remove_absolute(CUSTOM_MOVEMENTS_PATH);

func _on_reset_recording() -> void:
	recording = false;
	positions = vanilla_positions.duplicate();
	if FileAccess.file_exists(CUSTOM_MOVEMENTS_PATH):
		DirAccess.remove_absolute(CUSTOM_MOVEMENTS_PATH);

signal show_save_vanilla_logo_option;
