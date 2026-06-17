extends CanvasLayer

@onready var rich_text_label: RichTextLabel = $RichTextLabel;
@onready var og_text = rich_text_label.text;
@onready var timer: Timer = $Timer;

var time_string := "";

func _ready() -> void:
	_process(0);

func _process(_delta: float) -> void:
	var new_time_string := str(ceili(timer.time_left));
	if timer.is_stopped():
		new_time_string = "0";
	if new_time_string != time_string:
		time_string = new_time_string;
		rich_text_label.text = og_text.replace("[time]", time_string);
	

func end_disclaimer() -> void:
	timer.stop();
	Fades.fade_to_scene("res://scenes/TitleScreen/TitleScreen.tscn")

func _input(ev: InputEvent) -> void:
	if ev.is_pressed() && !ev.is_echo() && (
		ev is InputEventKey	or ev is InputEventJoypadButton or ev is InputEventMouseButton
	):
		end_disclaimer();
	if ev.is_action_pressed("setting_disclaimer"):
		OS.alert("Not here, *on the menu*.\nWhich I'm about to throw you into.", "Wrong screen.");

func _on_timer_timeout() -> void:
	end_disclaimer();
