extends Node

## this is where the serialized level is stored between scenes.
var load_level = null;
var level_manager: LevelManager = null;

# layer ids
const LAYER_A = (1 << 0);
const LAYER_B = (1 << 1);
const LAYER_EDITOR_OBJECTS = (1 << 3);
const LAYER_PLAYER = (1 << 4);
const LAYER_POLYGONS = (1 << 5);
const LAYER_MONITORS = (1 << 6);

# names of layers.
# this is used by LayeredTileset
const LAYER_A_NAME = "Collision A";
const LAYER_B_NAME = "Collision B";

const POP_SCENE := preload("res://objects/enemies/badnik/BadnikPop.tscn");

## Spwans a [BadnikPop].
# unused argument so it can be easily connected
# to the hurt signal (which is the case for most badniks)
func pop(node: Node2D):
	var explosion: BadnikPop = POP_SCENE.instantiate();
	explosion.global_position = node.global_position;
	explosion.play_sound = true;
	var parent := node.get_parent();
	parent.add_child(explosion);
	parent.move_child(explosion, node.get_index() - 1);
