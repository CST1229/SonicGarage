## Controls global sound effects.
##
## For example: [Ring]s, that need to have only 1 instance playing at a time
## and have the channel switching.
extends Node

## The audio stream player for [Ring]s.
var ring_player := AudioStreamPlayer.new();
## Toggles the channel ring sounds play on.
var other_ring_sound := false;

## Spindash is here because it uses an audio bus
## for the pitch shift effect,
## so to prevent weirdness we only let one instance play.
var spindash_player := AudioStreamPlayer.new();
## The pitch the spindash sound plays at.
var spindash_pitch = 0;

func _ready():
	ring_player.bus = "SFX";
	spindash_player.bus = "Spindash";
	spindash_player.stream = preload("res://objects/essential/Player/sounds/spindash.wav")
	
	var root = get_tree().root;
	root.add_child.call_deferred(ring_player);
	root.add_child.call_deferred(spindash_player);

## Plays a ring sound.
func play_ring():
	if !other_ring_sound:
		ring_player.stream = preload("res://objects/level/Ring/sounds/collect1.wav");
	else:
		ring_player.stream = preload("res://objects/level/Ring/sounds/collect2.wav");
	ring_player.play();
	other_ring_sound = !other_ring_sound;

## Plays a spindash sound.
func play_spindash():
	if !spindash_player.playing: spindash_pitch = 1;
	var bus = AudioServer.get_bus_index("Spindash");
	for i in range(AudioServer.get_bus_effect_count(bus)):
		var effect = AudioServer.get_bus_effect(bus, i);
		if effect is AudioEffectPitchShift:
			effect.pitch_scale = spindash_pitch;
	spindash_player.play();
	spindash_pitch += 0.075;
	spindash_pitch = clamp(spindash_pitch, 1, 3);

## Stops and resets the spindash sound.
func stop_spindash():
	spindash_player.stop();
	spindash_pitch = 1;
