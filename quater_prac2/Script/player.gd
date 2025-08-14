extends CharacterBody3D

#이동 변수
var input_dir : Vector2
var direction : Vector3
var SPEED : float = 7.0
var attack_speed : float = 5.5
var run_speed : float = 7.0
var accel : float = 10.0

#쳐다보기 변수
var view_dir : Vector3
var turn_accel: float = 10.0

#외부변수
@onready var cam_node : Node3D = $"../Camera" # 카메라 씬
@onready var cam3d : Camera3D = $"../Camera/CamPar/SpringArm3D/Camera3D" # 카메라 노드
@onready var target_effect : MeshInstance3D = $"../TargetEffect" # 마우스 위치 지정용 이펙트
@onready var attack_timer : Timer = $AttackHoldTimer # 공격모드 설정용 타이머

#애니메이션 변수
@onready var anim_player : AnimationPlayer = $AnimationPlayer
@onready var anim_tree : AnimationTree = $AnimationTree
var is_running : bool = false
var attack_anim_value : float = 0.0
var blend_pos : Vector2 = Vector2(0.0, 0.0)
var fin_blend_pos : Vector2

#쉐이더 변수
var effect_material : ShaderMaterial
var effect_shader_param : float = 0.0

#모드
var attack_mode : bool = false
signal attack_mode_signal
signal run_mode_signal

#피격 변수
signal player_hit

func _ready() -> void:
	view_dir = -global_transform.basis.z
	effect_material = target_effect.get_active_material(0)
	anim_tree.active = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

func _process(delta: float) -> void:
	if attack_mode:
		effect_shader_param = lerp(effect_shader_param, 1.0, delta * 10.0)
	else:
		effect_shader_param = lerp(effect_shader_param, 0.0, delta * 10.0)

func _physics_process(delta: float) -> void:
	basic_move(delta) #이동 관련
	cam_follow(delta) #카메라 따라오기
	mouse_effect(ray_cast(cam3d)) #마우스 레이캐스팅, 반환 포지션에 타겟 이펙트 붙이기
	if attack_mode:
		attacking() #공격모드 설정
	if !attack_mode:
		running() #러닝모드 설정
	anim_set()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.is_pressed(): # 누르는 동안을 감지
			attack_mode_signal.emit()
			attack_mode = true
			if attack_timer.is_stopped() == false: # 만약 타이머가 멈춰있지 않다면 타이머 정지
				attack_timer.stop()
		else:
			run_mode_signal.emit()
			#뗏을 때 3초 후 해제 타이머 시작
			#이미 돌고 있으면 다시 시작해서 남은 시간을 리셋
			attack_timer.start(3.0)


###############################
########## 기능 함수들 ##########
###############################

func basic_move(delta: float) -> void: #이동 관련
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	velocity = lerp(velocity, direction * SPEED, accel * delta)
	
	var final_view_dir : Vector3
	
	if attack_mode:
		final_view_dir = Vector3(target_effect.global_position.x, global_position.y, target_effect.global_position.z)
		look_at(final_view_dir, Vector3.UP)
	else:
		if direction.length() > 0: # direction 0일땐 아무것도 안하게
			view_dir = view_dir.slerp(direction, turn_accel * delta) # 서서히 회전
			final_view_dir = global_position + view_dir
			look_at(final_view_dir, Vector3.UP)
	
	move_and_slide()


func cam_follow(_delta: float) -> void: #카메라 따라오기
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
	effect_material.set_shader_parameter("factor", effect_shader_param) # 쉐이더 파라미터 설정

func attacking() -> void: #공격모드
	
	if is_running == true:
		is_running = false
	
	if SPEED > attack_speed:
		SPEED = attack_speed
		accel = 20.0
	attack_anim_value = lerp(attack_anim_value, 1.0, 0.5) # 블렌드 트리에서 공격모션으로 변경하는 프로퍼티
	blend_pos = lerp(blend_pos, input_dir, 0.3) # 8way 애니메이션 변환 속도
	
	##유튜브에서 얻은 코드
	var mov_dir = direction.normalized()
	var h_rot = get_rotation().y
	var b_pos = Vector3.ZERO
	b_pos = mov_dir.rotated(Vector3.UP, -h_rot).normalized()
	var b_pos_vec2 = Vector2(b_pos.x, -b_pos.z)
	fin_blend_pos = fin_blend_pos.lerp(b_pos_vec2, 0.5)
	
	##캐릭터 지역축 // GPT 코드
	#var right : Vector3 = global_transform.basis.x
	#var forward : Vector3 = -global_transform.basis.z
	#
	##입력을 월드 이동 벡터로 해석 ..
	#var world_move : Vector3 = right * blend_pos.x + forward * blend_pos.y
	#
	##blendspace2d에 넣을 로컬 성분 (캐릭터 기준)으로 다시 투영
	##X = 오른쪽(+), Y = 앞(+) 가 되도록 dot를 취합
	#var local_x = world_move.dot(right)
	#var local_y = world_move.dot(forward)
	#
	#fin_blend_pos = Vector2(local_x, local_y)
	#if fin_blend_pos.length_squared() > 0.000001:
		#fin_blend_pos = fin_blend_pos.normalized()
	#else:
		#fin_blend_pos = Vector2.ZERO
	
	
	##캐릭터 회전에 맞게 8way 포지션 회전 // 예전 코드
	#var char_rotate : float = global_basis.get_euler().y
	#var blend_pos_vector3 : Vector3 = Vector3(blend_pos.x, 0, blend_pos.y)
	#var new_rotated_vector3 : Vector3 = blend_pos_vector3.rotated(Vector3.UP, char_rotate)
	#fin_blend_pos = Vector2(new_rotated_vector3.x, new_rotated_vector3.z)
	#print(fin_blend_pos)

func running() -> void: #러닝모드
	if SPEED <= run_speed:
		SPEED = run_speed
		accel = 10.0
	attack_anim_value = lerp(attack_anim_value, 0.0, 0.5)
	if direction.length_squared() > 0.0001:
		is_running = true
	else:
		is_running = false

func anim_set() -> void:
	#블렌드트리, 러닝 컨디션 파라미터
	anim_tree.set("parameters/attack_select/blend_amount", attack_anim_value)
	anim_tree.set("parameters/running_state/conditions/start_run", is_running)
	anim_tree.set("parameters/running_state/conditions/stop_run", !is_running)
	
	#사격 이동
	anim_tree.set("parameters/8way/blend_position", fin_blend_pos)
	
func _on_attack_timer_timeout() -> void: # 공격모드 타이머
	attack_mode = false

func hit(damage: float) -> void:
	player_hit.emit()
