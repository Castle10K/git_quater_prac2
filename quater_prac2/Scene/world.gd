extends Node3D

#씬 컨트롤용 노드
@onready var hit_rect = $UI/ColorRect # 피격 UI 이미지
@onready var text_mob_count : TextEdit = $UI/TextMobCount # 몹카운트 수 텍스트 UI
@onready var text_kill_count : TextEdit = $UI/TextMobKill # 몹 킬 수 텍스트 UI

#몹 컨트롤용 노드
@onready var target_player : CharacterBody3D = $Player as CharacterBody3D
@onready var mob_gen : Node3D = $mob_gen # 몹 컨트롤러용 node3D
const MOB = preload("res://3DModel/mob/mob_anim.tscn") 

var mob_count : int = 0
var kill_count : int = 0

@onready var pathfollow3d : PathFollow3D = $Path3D/PathFollow3D
@onready var timer_mobgen: Timer = $Path3D/Timer_mobgen

var mobgen_pos : Vector3 = Vector3.ZERO

func _ready() -> void:
	pass




func _on_player_player_hit() -> void:
	hit_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	hit_rect.visible = false

func _on_timer_mobgen_timeout() -> void:
	
	var mob = MOB.instantiate() as CharacterBody3D
	mob.player = target_player # 몹의 target player에 여기 씬에서 가져운 player를 대입해라. (네비게이션 target용)
	mob.add_to_group("mobs")
	mob.connect("died", Callable(self,"_on_mob_died"))
	mob_gen.add_child(mob)
	
	mob.global_position = mob_gen_pos_select()
	_update_counts()
	

func mob_gen_pos_select() -> Vector3:
	
	var random_ratio = randf_range(0, 1)
	var random_offset = randi_range(-5, 5)
	
	pathfollow3d.set_progress_ratio(random_ratio)
	pathfollow3d.set_h_offset(random_offset)
	return pathfollow3d.global_position
	
func mob_count_ui() -> void:
	text_kill_count.text = "Kill : " + str(Global.kill_count)
	text_mob_count.text = "Mob : " + str(mob_count)
	
func _on_mob_died() -> void:
	_update_counts()

func _update_counts() -> void:
	
	var alive := get_tree().get_nodes_in_group("mobs").size()
	Global.mob_count = alive
	text_mob_count.text = "Mob :" + str(alive)
	text_kill_count.text = "Kill :" + str(Global.kill_count)
