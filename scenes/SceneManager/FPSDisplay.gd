extends Label

# FPS data isn't reliable for the first second
var show_timer := 0.0;
var prev_fps := -1.0;

func _ready():
	label_settings.font_color = Color(0.7, 0.7, 0.7);
	text = "?".repeat(str(int(DisplayServer.screen_get_refresh_rate())).length()) + " FPS";
	visible = Settings.show_fps;
	Settings.changed.connect(func(setting: StringName):
		if setting == &"show_fps":
			visible = Settings.show_fps;
	);

func _process(delta: float):
	if show_timer <= 1.0:
		show_timer += delta;
	elif visible:
		# var fps := int(1.0 / delta);
		var fps := Engine.get_frames_per_second();
		if fps != prev_fps:
			prev_fps = fps;
			update_fps_count(int(fps));

func update_fps_count(fps: int) -> void:
	text = "%s FPS" % fps;

	# green for stable framerates
	var refresh_rate := DisplayServer.screen_get_refresh_rate();
	var good_fps := 60.0;
	if refresh_rate < 0:
		refresh_rate = 60.0;
	good_fps = minf(good_fps, refresh_rate);
	
	var bad_fps := 15;
	
	var text_color := Color.WHITE;
	if (fps + 1) >= refresh_rate:
		text_color = Color(0.8, 1.0, 0.8);
	elif (fps + 1) >= good_fps:
		text_color = Color(0.9, 1.0, 0.9);
	elif fps <= bad_fps:
		text_color = Color(1.0, 0.3, 0.6);
	label_settings.font_color = text_color;
