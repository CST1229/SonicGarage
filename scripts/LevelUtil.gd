extends Node

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
