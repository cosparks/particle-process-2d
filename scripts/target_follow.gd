@tool
extends Node2D

@onready var _gpu_particles_material: ShaderMaterial = $GPUParticles2D.process_material;

func _physics_process(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position();
	_gpu_particles_material.set_shader_parameter("target_pos", mouse_pos);
