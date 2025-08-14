extends Node3D

#머즐플래쉬용
const MUZZLE_FLASH = preload("res://3DModel/MuzzleFlash/muzzle_flash.tscn")
var muzzle_flash : Node3D
@onready var marker3d = $Marker3D
@onready var shoot_sound = $Shotsound

#총알
const BULLET = preload("res://3DModel/Bullet/bullet.tscn")
var bullet : Node3D
var attack_damage = 20.0

#공격모드 확인
var attack_mode : bool = false

#쿨타임
@onready var cooldown = $Cooldown
@export var RPM := 300.0
@export var flash_time := 0.05
var fire_interval : float = 1 / (RPM / 60)

func _ready() -> void:
	muzzle_flash_onboard()
	cooldown.one_shot = true
	cooldown.wait_time = fire_interval
	

func _physics_process(_delta: float) -> void:
	if attack_mode and cooldown.is_stopped():
		gun_shoot() # 사격 컨트롤 함수
	#print(cool_time)


####################
######기능함수들######
####################


#공격
func gun_shoot() -> void:
	shoot_sound.play()
	_show_muzzle_flash()
	cooldown.start()
	
	#총알 생성
	var b := BULLET.instantiate() as Node3D
	get_tree().current_scene.add_child(b)
	b.damage = attack_damage
	#marker의 트랜스폼 복사
	b.global_transform = marker3d.global_transform
	var dir : Vector3 = -marker3d.global_transform.basis.z
	if b.has_method("set_fire_dir"):
		b.call("set_fire_dir", dir) # 그냥 점찍고 파라미터 쓰면 되는거 아닌가 ? 잘 모르겠네
		#b.set_fire_dir(dir) #이러면 되는거 아닌교 ?

func _show_muzzle_flash() -> void:
	muzzle_flash.visible = true
	await get_tree().create_timer(flash_time).timeout
	muzzle_flash.visible = false
	muzzle_flash.rotate_z(randf_range(-PI, PI))
	var random_value : float = randf_range(0.8, 1.1)
	var muzzle_scale : Vector3 = Vector3(random_value, random_value, random_value)
	muzzle_flash.scale = muzzle_scale

func muzzle_flash_onboard() -> void:
	muzzle_flash = MUZZLE_FLASH.instantiate() as Node3D
	marker3d.add_child(muzzle_flash)
	muzzle_flash.global_transform.origin = marker3d.global_transform.origin
	if muzzle_flash.visible == true:
		muzzle_flash.visible = false



#공격 버튼 누를때
func _on_player_attack_mode_signal() -> void:
	if !attack_mode:
		await get_tree().create_timer(0.05).timeout
		attack_mode = true

#공격 버튼 뗄때
func _on_player_run_mode_signal() -> void:
	if attack_mode:
		attack_mode = false
