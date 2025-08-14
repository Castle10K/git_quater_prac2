extends Node3D

#변수들
var life_time : float = 5.0
var bullet_speed : float = 50.0
var fire_dir : Vector3 = Vector3.ZERO
var damage : float

#외부 변수들
@onready var raycast3d: RayCast3D = $RayCast3D
@onready var particles : GPUParticles3D = $GPUParticles3D
@onready var bullet_transform_ctrl : Node3D = $transform

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	global_translate(fire_dir * bullet_speed * delta)
	
	if raycast3d.is_colliding():
		var ray_collision_pos = raycast3d.get_collision_point()
		var collider = raycast3d.get_collider()
		if collider.has_method("take_damage"):
			collider.take_damage(damage)
			
		particles.global_position = ray_collision_pos
		
		
		bullet_transform_ctrl.visible = false
		particles.emitting = true
		await get_tree().create_timer(1.0).timeout
		
		queue_free()

func set_fire_dir(dir: Vector3) -> void:
	fire_dir = dir.normalized()


func _on_timer_timeout() -> void:
	queue_free()
