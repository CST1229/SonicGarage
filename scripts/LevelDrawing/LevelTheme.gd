@tool
class_name LevelTheme
extends Resource

@export var base_texture: String;
@export var decors: Array[Decor] = [];
@export var mutually_exclusive: Array[Array];
## *Inverse* scale of the base "fill" texture on polygons.
@export var base_texture_scale := 1.0;

## Indexes that decide which decor takes precedence in case of a
## mutually_exclusive conflict.
var _decor_precedence: Dictionary[Decor, int] = {};
## Decors that can't coexist on one vertex.
## If both decors match a vertex, the one that wins will be
## the one earlier in the theme's decors array.
var _mutually_exclusive: Dictionary[Decor, Array];

static func create(_base_texture: String, _decors: Array[Decor], param_mutually_exclusive: Array[Array] = [], _base_texture_scale := 1.0) -> LevelTheme:
	var theme := new();
	theme._create(_base_texture, _decors, param_mutually_exclusive, _base_texture_scale)
	return theme;
	
func _create(_base_texture: String, _decors: Array[Decor], param_mutually_exclusive: Array[Array] = [], _base_texture_scale := 1.0):
	base_texture = _base_texture;
	decors = _decors;
	mutually_exclusive = param_mutually_exclusive;
	base_texture_scale = _base_texture_scale;

func _init():
	update.call_deferred();
	changed.connect(update);
	
func update():
	if decors:
		for i in range(decors.size()):
			_decor_precedence[decors[i]] = i;
	if mutually_exclusive:
		# convert the convienient array declaration into the spaghetti dictionary
		# used by the decor rendering code
		_mutually_exclusive = {};
		for decor_group in mutually_exclusive:
			for decor in decor_group:
				if !(decor in _mutually_exclusive):
					_mutually_exclusive[decor] = [];
				for target_decor in decor_group:
					if !(target_decor in _mutually_exclusive[decor]):
						_mutually_exclusive[decor].append(target_decor);
