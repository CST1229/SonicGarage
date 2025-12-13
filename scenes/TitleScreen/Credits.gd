extends URLRichTextLabel

func _ready() -> void:
	super();
	text = text.replace("[music_credits]", get_music_credits());

func _physics_process(delta: float) -> void:
	if is_visible_in_tree():
		get_v_scroll_bar().value += Input.get_axis("ui_up", "ui_down") * delta * 200.0;

func get_music_credits() -> String:
	var credits = "";
	for song in LevelUtil.songs.values():
		if song.path != "":
			credits += " - {0}: {1}, by {2}\n".format([song.as_seen_in, song.name, song.author]);
	return credits.strip_edges(false, true);
