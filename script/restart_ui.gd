extends CanvasLayer

signal start_game

const win_msg_array = ["成功！勤能补拙，笨鸟先飞！","成功！眼疾手快，熟能生巧！","成功！振翅破风云，终成翱翔者！"]
const lose_msg_array = ["笨鸟先飞，多试必达。","屡败屡战，终将先飞。","差之毫厘，下次翱翔。"]

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func update_result(is_success):
	if is_success:
		$%"ResultMessageLabel".text = win_msg_array[randi() % 3]
		$%"FireworksAnimation".play()
	else:
		$%"ResultMessageLabel".text = lose_msg_array[randi() % 3]	

func update_score(value):
	$%"ScoreLabel".text = "分数：" + str(value)

func update_level(value):
	$%"LevelLabel".text = "关卡：" + str(value)

func _on_restart_button_pressed():
	$%"FireworksAnimation".stop()
	emit_signal("start_game")
