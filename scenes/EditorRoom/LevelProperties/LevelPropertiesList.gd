extends VBoxContainer

var level_container: LevelContainer;
@onready var music: OptionButton = $Grid/Music;
@onready var music_credit: Label = $Grid/MusicCredit;

@export var level_container_from: Node;

var song_ids := PackedStringArray();

func _ready() -> void:
	level_container = level_container_from.level_container;
	
	var i := 0;
	for song_id in Global.songs:
		song_ids.append(song_id);
		music.add_item(Global.songs[song_id].name, i);
		i += 1;
	
	music.item_selected.connect(func(index: int) -> void:
		if index >= 0:
			level_container.music = song_ids[index];
			level_container.play_music();
			level_container.dirty = true;
			music_changed();
	);
	music.selected = song_ids.find(level_container.music);
	music_changed();

func music_changed() -> void:
	if level_container.music not in Global.songs:
		music_credit.text = "???";
	else:
		music_credit.text = Global.songs[level_container.music].author;
		pass
