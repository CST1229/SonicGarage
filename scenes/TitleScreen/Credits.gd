extends URLRichTextLabel

func _ready() -> void:
	super();
	text = text.replace("[music_credits]", get_music_credits());

func _physics_process(delta: float) -> void:
	if is_visible_in_tree():
		get_v_scroll_bar().value += Input.get_axis("ui_up", "ui_down") * delta * 200.0;

func get_music_credits() -> String:
	var credits = "";
	for song_id in Global.songs:
		var song := Global.songs[song_id];
		if song.path != "":
			var start_tag := "";
			var end_tag := "";
			if song_id == "blue_ska":
				start_tag = '[hint="Ctrl+Shift+Play?"]'
				end_tag = "[/hint]";
			credits += " - {0}{1}{4}{5}{2}, by {3}\n".format(
				[
					start_tag, song.as_seen_in, song.name,
					song.author, end_tag, ": " if song.as_seen_in else ""
				]
			);
	return credits.strip_edges(false, true);
