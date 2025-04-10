## Contains control handles for customizing objects.
##
## Gets destroyed when not in the editor,
## and otherwise shown/hidden while the object is selected/deselected.
## Is to be placed inside objects, like:
## [codeblock]
## AnObject
## |- [Control]<script: HandleContainer> ([member HandleContainer.target] = AnObject)
##    |- [RectResizerHandle] ([member RectResizerHandle.target] = AnObject)
## [/codeblock]
extends Control
class_name HandleContainer

## The node the container is for.
@export var target: Node;
## The editor to check for. If none is present,
## the container destroys itself.
var editor: LevelEditor;

var use_size = false;

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE;
	visible = false;
	var container: LevelContainer = find_container();
	if !target || !container || !container.editor_mode:
		queue_free();
		return;
	editor = container.editor;
	use_size = "size" in target;

func _process(_delta: float):
	visible = target.is_in_group(&"selected_objects") && editor.tool == LevelEditor.Tool.OBJECT_SELECT;
	update_size();

func update_size():
	if !use_size: return;
	size = target.size;
	position = size * -0.5;

## Finds the level container.
## TODO: maybe this should be part of [EditorLib].
func find_container():
	var container = self;
	while !(container is LevelContainer):
		container = container.get_parent();
		if !container: return;
	return container;
