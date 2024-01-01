extends CharacterBody2D
class_name Badnik

enum BounceType {
	NORMAL,
	BOSS,
	NONE
}

var bounce_type := BounceType.NORMAL;

# unused argument so it can be easily connected
# to the hurt signal (which is the case for most badniks)
func pop(_inflictor = null):
	LevelUtil.pop(self);
	queue_free();

func _on_touch_hitbox(body: Node2D):
	if body.has_signal("touch_badnik"):
		body.touch_badnik.emit(self, bounce_type);
func _on_touch_hurtbox(body: Node2D):
	if body.has_signal("hurt"):
		body.hurt.emit(self);

signal hurt(inflictor: Node2D);
signal touch_hitbox(body: Node2D);
signal touch_hurtbox(body: Node2D);
