extends Panel

@export var level_container: LevelContainer;

@onready var back_button: Button = $BackButton;
@onready var scroll_container: ScrollContainer = $HMargin/ScrollContainer;

@onready var music: FixedOptionButton = %Music;
@onready var music_credit: Label = %MusicCredit;
@onready var level_theme: FixedOptionButton = %Theme;

var song_ids := PackedStringArray();
var theme_ids := PackedStringArray();

func entered() -> void:
	scroll_container.scroll_vertical = 0;
	back_button.grab_focus();
	
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
	music.make_option_button_items_non_radio_checkable();
	
	i = 0;
	for theme_id in Global.level_themes:
		theme_ids.append(theme_id);
		var theme_def: LevelThemeDef = load(Global.level_themes[theme_id]);
		level_theme.add_icon_item(theme_def.icon, theme_def.resource_name, i);
		i += 1;
	level_theme.selected = theme_ids.find(level_container.theme_id);
	
	level_theme.item_selected.connect(func(index: int) -> void:
		if index >= 0:
			level_container.theme_id = theme_ids[index];
			level_container.dirty = true;
			level_container.update_theme();
	);
	level_theme.make_option_button_items_non_radio_checkable();

func music_changed() -> void:
	if level_container.music not in Global.songs:
		music_credit.text = "???";
	else:
		music_credit.text = Global.songs[level_container.music].author;
		pass



func _on_back_button_pressed() -> void:
	go_back.emit();

signal go_back
