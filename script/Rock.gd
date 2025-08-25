extends RigidBody2D

const object_type = "Rock"
var rock_pair_id = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func _on_visible_on_screen_notifier_2d_screen_exited():
	# 延迟销毁，避免边缘还未离开屏幕就销毁
	await get_tree().create_timer(0.5).timeout
	queue_free()
