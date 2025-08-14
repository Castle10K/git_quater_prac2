extends CharacterBody3D

#기본 좀비 스탯
const SPEED : float = 3.5
const ATTACK_RANGE : float = 1.5
var health : float = 100.0
var attack_damage : float = 10.0

#외부 노드 입력
@export var player : CharacterBody3D
@onready var navi_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player : AnimationPlayer = $AnimationPlayer
@onready var anim_tree : AnimationTree = $AnimationTree

@onready var boneattach : BoneAttachment3D = $Armature/GeneralSkeleton/BoneAttachment3D
@onready var collision : CollisionShape3D = $CollisionShape3D

#체력바
@onready var subviewport = $SubViewport
@onready var health_bar = $SubViewport/ProgressBar

#애니메이션
var state_machine

#사운드
@onready var death_audio : AudioStreamPlayer3D = $death_sound

#머티리얼
@onready var mesh : MeshInstance3D = $Armature/GeneralSkeleton/Ch36

#죽는 모드
var death_mode : bool = false
signal died

func _ready() -> void:
	
	state_machine = anim_tree.get("parameters/playback")
	health_bar.value = health
	

func _physics_process(delta: float) -> void:
	#콜리전을 본 어태치먼트 위치에 붙이기
	collision.global_transform = boneattach.global_transform
	
	#공격 거리 내에는 attack 애니메이션 루프모드, 거리 밖일땐 루프 풀기. 그래야 run transition으로 진입 가능
	
	#애니메이션 플레이어는 인스턴스 전체 적용이다... 따라서 인스턴스 하나만 있을때는 아래 loop_mode가 잘 작동하지만,
	#인스턴스가 2개 이상이면 하나라도 공격범위 밖에 있을땐 attack 모드의 loop가 0으로 세팅된다.
	#함수의 return은 글로벌 적용인가 ?
	
	var target_in = _target_in_range()
	
	if target_in:
		anim_player.get_animation("Attack").loop_mode = Animation.LOOP_LINEAR
	if !target_in:
		anim_player.get_animation("Attack").loop_mode = Animation.LOOP_NONE
	
	
	match state_machine.get_current_node():
		
		"Run":
			velocity = Vector3.ZERO
			navi_agent.set_target_position(player.global_transform.origin)
			var next_pos = navi_agent.get_next_path_position()
			velocity = (next_pos - global_position).normalized() * SPEED
			look_at(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z), Vector3.UP, true)
		
		"Attack":
			velocity = Vector3.ZERO
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP, true)
	
	if death_mode:
		velocity = lerp(velocity, Vector3.ZERO, delta * 2.0)
	
	
	#애니메이션 컨디션 컨트롤
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())
	
	move_and_slide()
	
	if health <= 0:
		death()

func attack() -> void:
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		if player.has_method("hit"):
			player.hit(attack_damage)

func take_damage(taking_damage: float) -> void:
	if death_mode:
		return
	health -= taking_damage
	health_bar.value = health
	print(health)

func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE

func death() -> void:
	if death_mode: return
	death_mode = true
	remove_from_group("mobs")
	Global.kill_count += 1
	
	health_bar.hide() # 헬스바 숨김
	
	death_audio.play()
	
	emit_signal("died")
	collision.disabled = true
	set_physics_process(false)
	anim_tree.set("parameters/conditions/die", true)
	
	await get_tree().create_timer(3.0).timeout
	
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(
		mesh,
		"instance_shader_parameters/controller",
		1.0,
		1.2
	)
	await tw.finished
	#anim_tree.animation_finished
	queue_free()
	
