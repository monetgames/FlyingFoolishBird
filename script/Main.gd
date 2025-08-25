extends Node2D

signal sig_update_score(int)
signal sig_update_level(int)
signal sig_result(bool)
signal sig_update_bird_speed(int)

const rock_scene = preload("../rock.tscn")
const bug_scene = preload("../bug.tscn")

# 数组size等于关卡数，数组每项代表每一关生成岩石的间隔时间
const rock_time_array = [3, 2.4, 1.9, 1.5, 1.2, 1, 0.8, 0.7]

const each_level_rock_pair_num = 10 # 每关的岩石对数
const default_speed = 200			# 默认鸟和岩石的速度

var is_game_playing = false			# 游戏是否运行中
var score = 0						# 分数
var level = 1						# 关卡

var rock_pair_num = 0				# 生成的岩石数量
var rock_pair_passed_id = 0			# 最后通过的岩石id
var cur_rock_speed = default_speed	# 当前岩石移动速度

var bug_num = 0						# 生成的虫子数量

# 用于关卡之间等待逻辑
var is_waiting_level_transition = false # 等待关卡切换状态
var is_level_pause_over = false		# 关卡间暂停计时器结束
var current_level_last_rock_id = 0	# 当前关卡最后一对岩石id


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	# 信号槽
	self.sig_update_score.connect($RestartUI.update_score)
	self.sig_update_level.connect($RestartUI.update_level)
	self.sig_result.connect($RestartUI.update_result)
	self.sig_update_score.connect($LevelScoreUI.update_score)
	self.sig_update_level.connect($LevelScoreUI.update_level)
	self.sig_update_bird_speed.connect($LevelScoreUI.update_bird_speed)
	self.sig_update_level.connect(_on_update_level)
	$AudioGameBGM.finished.connect(_on_audio_game_BGM_finished)
	
	# 开始游戏
	start_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("ui_accept"):
		if is_game_playing == false and $RestartUI.visible == true:
			start_game()
		
		
func _physics_process(delta):
	if is_game_playing:
		# 遍历上面的岩石数组
		for rock_pair in $RockUp.get_children():
			# 如果当前岩石id大于最后通过的岩石id，并且当前岩石被鸟飞过去了，则加一分
			if rock_pair.rock_pair_id > rock_pair_passed_id and rock_pair.position.x < $Bird.position.x:
				# 更新鸟最后通过的岩石id
				rock_pair_passed_id = rock_pair.rock_pair_id
				# 更新分数
				set_score(score + 1)

				# 游戏通关判断：当累计通过的岩石对数达到总岩石对数时视为通关
				var total_rock_pairs = rock_time_array.size() * each_level_rock_pair_num
				if score >= total_rock_pairs:
					$GameSuccessWaitTimer.start()
					return

				# 若处于“已生成完本关岩石，等待关卡切换”的状态，并且小鸟已经通过了本关最后一对岩石，
				# 同时关卡间暂停计时器也已到（level_pause_over），则在此处完成关卡切换并继续生成下一关
				if is_waiting_level_transition and rock_pair_passed_id >= current_level_last_rock_id and is_level_pause_over:
					_start_next_level()

				print("main level="+str(level), "\tscore=" + str(score))


func _on_restart_ui_start_game():
	print("main _on_restart_ui_start_game")
	start_game()

	
# 游戏开始
func start_game():
	is_game_playing = true
	print("main start_game")
	rock_pair_passed_id = 0
	rock_pair_num = 0
	bug_num = 0
	set_score(0)
	set_level(1)
	set_bird_speed(default_speed)
	$RestartUI.hide()
	$Bird.start($StartPosition.position)
	$AudioGameBGM.play()
	$CreateRockTimer.start()
	
# 游戏结束
func game_over(is_success):
	is_game_playing = false
	print("main ganme_over")
	emit_signal("sig_result", is_success)
	$AudioGameBGM.stop()
	if is_success:
		$AudioGameWin.play()
	else:
		$AudioGameLose.play()
	$RestartUI.show()
	$Bird.die()
	$CreateRockTimer.stop()
	for item in $RockUp.get_children():
		item.queue_free()
	for item in $RockDown.get_children():
		item.queue_free()
	for item in $BugNode.get_children():
		item.queue_free()


# 生成岩石对（上下各一个岩石）、虫子
func create_rock_pair():
	# 生成岩石对
	var rock_up_y = randf_range(-168, 192)
	var rock_down_y = rock_up_y + 576
	var velocity = Vector2(-cur_rock_speed, 0.0)
	rock_pair_num = rock_pair_num + 1

	var rock_up = rock_scene.instantiate()
	rock_up.rotate(3.14)
	rock_up.position = Vector2(880, rock_up_y)
	rock_up.set_linear_velocity(velocity)
	rock_up.rock_pair_id = rock_pair_num
	$RockUp.add_child(rock_up)

	var rock_down = rock_scene.instantiate()
	rock_down.position = Vector2(880, rock_down_y)
	rock_down.set_linear_velocity(velocity)
	rock_down.rock_pair_id = rock_pair_num
	$RockDown.add_child(rock_down)
	
	# 生成虫子
	var bug_y = rock_up_y + randf_range(220, 360)
	bug_num = bug_num + 1
	var new_bug = bug_scene.instantiate()
	new_bug.born(bug_num, Vector2(880, bug_y))
	new_bug.set_linear_velocity(velocity)
	$BugNode.add_child(new_bug)


# 鸟碰到 body
func _on_bird_body_entered(body):
	if body.get("object_type") != null:
		# 鸟碰到了岩石，游戏结束
		if body.object_type == "Rock":
			game_over(false)
		# 鸟碰到了虫子，吃虫子
		elif body.object_type == "Bug":
			eat_bug(body)


# 调整关卡难度
func _on_update_level(value):
	if value < 1:
		return
	var create_rock_wait_timer = rock_time_array[value-1]
	$CreateRockTimer.wait_time = create_rock_wait_timer

	# 难度调整拟合函数
	cur_rock_speed = 470 - 95 * create_rock_wait_timer
	print("main _on_update_level="+str(value) + "\tcreate_rock_wait_timer=" + str(create_rock_wait_timer)+ "\trock_speed="+str(cur_rock_speed))


# 在条件满足时开始下一关
func _start_next_level():
	# 若不是处于等待过渡状态，直接返回（防止重复调用）
	if not is_waiting_level_transition:
		return

	# 立即清理等待状态，防止再次触发
	is_waiting_level_transition = false
	is_level_pause_over = false

	# 停止关卡等待计时器（若仍在运行）
	if $UpdateLevelWaitTimer.is_stopped() == false:
		$UpdateLevelWaitTimer.stop()

	# 更新关卡（若尚未到最大关）
	if level < rock_time_array.size():
		set_level(level + 1)

	# 由 CreateRockTimer 统一生成下一关的岩石对
	if $CreateRockTimer.is_stopped():
		$CreateRockTimer.start()


# 吃一个虫子
func eat_bug(bug_body):
	$Bird.eat()
	# 速度+100
	set_bird_speed($Bird.bird_speed + 20)
	bug_body.die()

func _on_audio_game_BGM_finished():
	$AudioGameBGM.play()

func set_level(value):
	level = value
	emit_signal("sig_update_level", value)

func set_score(value):
	score = value
	emit_signal("sig_update_score", value)
	
func set_bird_speed(value):
	$Bird.bird_speed = value
	emit_signal("sig_update_bird_speed", int(value))


func _on_game_success_wait_timer_timeout():
	game_over(true)


# 计时器 CreateRockTimer 的 timeout 信号
func _on_create_rock_timer_timeout():
	# 总共需要生成的岩石对数
	var total_rock_pairs = rock_time_array.size() * each_level_rock_pair_num

	# 如果已生成完所有关卡的岩石对，则停止
	if rock_pair_num >= total_rock_pairs:
		$CreateRockTimer.stop()
		return

	# 统一由 CreateRockTimer 生成岩石对（先生成，再判断是否到达本关生成上限）
	create_rock_pair()

	# 若刚生成后达到了本关该生成的数量（即每关已生成完），则暂停生成并等待关卡更新
	if rock_pair_num % each_level_rock_pair_num == 0:
		$CreateRockTimer.stop()
		# 标记当前关最后一对岩石 id，并进入等待状态（等待 UpdateLevelWaitTimer 完成以及鸟通过）
		current_level_last_rock_id = rock_pair_num
		is_waiting_level_transition = true
		is_level_pause_over = false
		$UpdateLevelWaitTimer.start()


# 计时器 UpdateLevelWaitTimer 的 timeout 信号
func _on_update_level_wait_timer_timeout() -> void:
	# 如果已生成完所有关卡岩石对，不再重启生成计时器
	var total_rock_pairs = rock_time_array.size() * each_level_rock_pair_num
	if rock_pair_num >= total_rock_pairs:
		return

	# 只标记关卡间暂停已结束，不直接改关卡（因为小鸟可能尚未飞过本关最后一对岩石）
	is_level_pause_over = true

	# 如果小鸟已飞过本关最后一对岩石，则在此处立即开始下一关
	if is_waiting_level_transition and rock_pair_passed_id >= current_level_last_rock_id:
		_start_next_level()
