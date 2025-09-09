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

var container: LevelContainer;

var use_size = false;

var last_visible = false;

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE;
	visible = false;
	container = find_container();
	disable_process();
	if !target || !container || !container.editor_mode:
		queue_free();
		return;
	editor = container.editor;
	process_mode = Node.PROCESS_MODE_ALWAYS;
	use_size = "size" in target;

func _process(_delta: float):
	visible = target.is_in_group(&"selected_objects") && editor.tool == LevelEditor.Tool.OBJECT_SELECT;
	if last_visible != visible:
		last_visible = visible;
		if visible:
			enable_process();
		else:
			disable_process();
	if visible:
		update_size();

func update_size():
	if !use_size: return;
	size = target.size;
	position = size * -0.5;

func disable_process():
	for child in get_children():
		child.process_mode = Node.PROCESS_MODE_DISABLED;
func enable_process():
	for child in get_children():
		child.process_mode = Node.PROCESS_MODE_ALWAYS;

## Finds the level container.
## TODO: maybe this should be part of [EditorLib].
func find_container() -> LevelContainer:
	var new_container: Node = self;
	while !(new_container is LevelContainer):
		new_container = new_container.get_parent();
		if !new_container: return;
	return new_container as LevelContainer;
