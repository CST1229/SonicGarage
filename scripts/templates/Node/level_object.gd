# meta-name: Level Object
# meta-description: An object that can be placed in the editor.
extends _BASE_

# You must also add this object's scene (and ID) to Global.object_list in res://scripts/global.gd.
# You should also add an EditorObjectBounds node, and optionally a HandleContainer with handles inside if you want your object to be customizable.

## The level containing this object.
var container: LevelContainer;

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	# Stop physics from running in the editor.
	if container && container.editor_mode:
		return;
	pass

func serialize() -> Dictionary:
	return {
		# Properties to serialize go here.
		# Must be JSON-serializable (number/bool/string/dict/array/null only).
	};

func deserialize(json: Dictionary) -> void:
	# `json` is the properties returned in serialize()/in the level file.
	# Apply them here.
	pass
