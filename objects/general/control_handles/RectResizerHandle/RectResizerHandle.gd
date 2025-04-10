## A control handle that lets the user resize the object as a rectangle.
##
## Requires a "size" property on the target object,
## and is made for objects which scale from the center.
extends Control

@export var snap: Vector2 = Vector2.ONE;

const HANDLES: Array[Vector2] = [
	Vector2(0, -0.5),
	Vector2(0, 0.5),
	Vector2(-0.5, 0),
	Vector2(0.5, 0),
	
	Vector2(-0.5, -0.5),
	Vector2(-0.5, 0.5),
	Vector2(0.5, 0.5),
	Vector2(0.5, -0.5),
];

# handle position -> node map
var handle_nodes = {};

@export var target: Node2D;

func _ready():
	if !target || target.is_queued_for_deletion():
		visible = false;
		queue_free();
		return;
	
	# set the inner handles up
	for handle in HANDLES:
		var node: Control = Control.new();
		node.script = preload("res://objects/general/control_handles/RectResizerHandle/ResizerHandleInner.gd");
		
		node.handle = handle;
		node.snap = snap;
		node.target = target;
		
		var anchor: Vector2 = handle + Vector2(0.5, 0.5);
		node.anchor_left = anchor.x;
		node.anchor_right = anchor.x;
		node.anchor_top = anchor.y;
		node.anchor_bottom = anchor.y;
		
		handle_nodes[handle] = node;
		
		add_child(node);
