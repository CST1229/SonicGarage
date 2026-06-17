class_name EditorRoom
extends EditorRoomBase

@onready var camera: Camera2D = $Camera;
@onready var level_editor: LevelEditor = $LevelEditor;

@onready var playtest_trails: Line2D = $PlaytestTrails;

func _ready() -> void:
	super();
	if LevelUtil.load_params.newly_loaded_level:
		LevelUtil.load_params.playtest_trails.clear();
		LevelUtil.load_params.newly_loaded_level = false;
		camera.position = level_container.player_start_pos;
	else:
		camera.position = LevelUtil.load_params.editor_camera_pos;
		level_editor.zoom = LevelUtil.load_params.editor_camera_zoom;
		level_editor.apply_camera_zoom();
	
	if !LevelUtil.load_params.playtest_trails.is_empty():
		playtest_trails.points = LevelUtil.load_params.playtest_trails;

func playtest() -> void:
	if playtest_room:
		LevelUtil.load_params.editor_camera_pos = camera.position;
		LevelUtil.load_params.editor_camera_zoom = level_editor.zoom;
		LevelUtil.load_params.level = level_container.serialize();
		LevelUtil.load_params.is_playtesting_from_pos = \
			Input.is_action_pressed(&"editor_scroll_fast");
		LevelUtil.load_params.playtest_pos = get_local_mouse_position();
		super();

func exit() -> void:
	if level_container && level_container.editor_mode:
		LevelUtil.load_params.level = level_container.serialize();
	super();
