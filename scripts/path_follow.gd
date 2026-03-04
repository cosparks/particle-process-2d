@tool
extends Node2D

@onready var _process_material: ShaderMaterial = $GPUParticles2D.process_material;
@onready var _path: Line2D = $Path;

func _ready() -> void:
	_init_path.call_deferred();

func _init_path() -> void:
	_path.draw.connect(_on_path_changed);
	_process_material.set_shader_parameter("path", _path.points);
	_process_material.set_shader_parameter("path_length", _path.points.size());

func _on_path_changed() -> void:
	print("path changed");
	_process_material.set_shader_parameter("path", _path.points);
	_process_material.set_shader_parameter("path_length", _path.points.size());
