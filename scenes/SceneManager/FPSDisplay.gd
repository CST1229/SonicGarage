extends Label

# FPS data isn't reliable for the first second
var show_timer := 0.0;

func _process(delta: float):
	show_timer += delta;
	visible = Settings.show_fps;
	if visible:
		#var fps := (1.0 / delta);
		var fps := Engine.get_frames_per_second();
		var fps_str := str(int(fps));
		if show_timer <= 1.0:
			fps_str = "?".repeat(str(int(DisplayServer.screen_get_refresh_rate())).length());
			fps = -1;
		text = "%s FPS" % fps_str;
	
		# green for stable framerates
		var refresh_rate := DisplayServer.screen_get_refresh_rate();
		var good_fps := 60.0;
		if refresh_rate == -1:
			refresh_rate = 60.0;
		good_fps = minf(good_fps, refresh_rate);
		
		var bad_fps := 15;
		
		var text_color = Color.WHITE;
		if fps == -1:
			text_color = Color(0.7, 0.7, 0.7);
		elif (fps + 1) >= refresh_rate:
			text_color = Color(0.8, 1.0, 0.8);
		elif (fps + 1) >= good_fps:
			text_color = Color(0.9, 1.0, 0.9);
		elif fps <= bad_fps:
			text_color = Color(1.0, 0.3, 0.6);
		label_settings.font_color = text_color;
