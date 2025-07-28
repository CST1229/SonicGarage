extends Label

func _process(delta: float):
	visible = Settings.show_fps;
	if visible:
		var fps := (1.0 / delta);
		text = "{0} FPS".format([int(roundf(fps))]);
	
		# green for stable framerates
		var refresh_rate := DisplayServer.screen_get_refresh_rate();
		var good_fps := 60.0;
		if refresh_rate == -1:
			refresh_rate = 60.0;
		good_fps = minf(good_fps, refresh_rate);
		
		var bad_fps := 5;
		
		modulate = Color.WHITE;
		if (fps + 1) >= refresh_rate:
			modulate = Color(0.8, 1.0, 0.8);
		elif (fps + 1) >= good_fps:
			modulate = Color(0.9, 1.0, 0.9);
		elif fps <= bad_fps:
			modulate = Color(1.0, 0.8, 0.8);
