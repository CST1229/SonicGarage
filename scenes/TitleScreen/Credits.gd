extends RichTextLabel

func _ready():
	text = text.replace("[music_credits]", get_music_credits());

func get_music_credits() -> String:
	var credits = "";
	for song in LevelUtil.songs.values():
		if song.path != "":
			credits += " - {0}: {1} by {2}\n".format([song.as_seen_in, song.name, song.author]);
	return credits.strip_edges(false, true);
