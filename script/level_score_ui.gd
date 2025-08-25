extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_level(value):
	$LevelLabel.text = "关卡：" + str(value)
	
func update_score(value):
	$ScoreLabel.text = "分数：" + str(value)

func update_bird_speed(value):
	$SpeedLabel.text = "速度：" + str(value)
