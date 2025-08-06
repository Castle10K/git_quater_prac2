extends CharacterBody3D

#이동 변수
var input_dir : Vector2
var direction : Vector3
const SPEED : float = 8.0
var accel : float = 10.0

#쳐다보기 변수
var view_dir : Vector3 = -global_transform.basis.z
var turn_accel: float = 10.0

#외부변수
@onready var cam_node : Node3D = $"../Camera" # 카메라 씬
@onready var cam3d : Camera3D = $"../Camera/CamPar/SpringArm3D/Camera3D" # 카메라 노드
@onready var target_effect : MeshInstance3D = $"../TargetEffect"

#쉐이더 변수
var effect_material : ShaderMaterial
var effect_shader_param : float = 0.0

#모드
var attack_mode : bool = false

func _ready() -> void:
	effect_material = target_effect.get_active_material(0)

func _process(delta: float) -> void:
	if attack_mode:
		effect_shader_param = lerp(effect_shader_param, 1.0, delta * 10.0)

func _physics_process(delta: float) -> void:
	basic_move(delta) #이동 관련
	cam_follow(delta) #카메라 따라오기
	mouse_effect(ray_cast(cam3d)) #마우스 레이캐스팅, 반환 포지션에 타겟 이펙트 붙이기
	if attack_mode:
		attacking() #공격모드 설정

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if !attack_mode:
				attack_mode = true

###############################
########## 기능 함수들 ##########
###############################

func basic_move(delta: float) -> void: #이동 관련
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	velocity = lerp(velocity, direction * SPEED, accel * delta)
	
	if direction:
		view_dir = view_dir.slerp(direction, turn_accel * delta) # 서서히 회전
		look_at(global_position + view_dir)
	
	move_and_slide()

func cam_follow(delta: float) -> void: #카메라 따라오기
	cam_node.global_position = global_position

func ray_cast(cam: Camera3D) -> Vector3: #마우스 레이캐스팅
	var world_state = cam.get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var from = cam.project_ray_origin(mouse_pos)
	var to = from + cam.project_ray_normal(mouse_pos) * 100.0
	var quary = PhysicsRayQueryParameters3D.create(from, to)
	
	quary.collide_with_areas = false
	quary.collide_with_bodies = true
	quary.exclude = [self]
	
	var result = world_state.intersect_ray(quary)
	
	if result:
		return result.position
	else:
		return Vector3.ZERO

func mouse_effect(mouse_pos: Vector3) -> void:
	if mouse_pos == Vector3.ZERO:
		target_effect.visible = false
	else:
		target_effect.visible = true
		target_effect.global_position = mouse_pos

func attacking() -> void:
	effect_material.set_shader_parameter("factor", effect_shader_param)
