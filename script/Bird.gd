extends Area2D

var bird_speed : int
var screen_size # Size of the game window.

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		velocity = Vector2.UP * bird_speed
	elif Input.is_action_pressed("ui_down"):
		velocity = Vector2.DOWN * bird_speed
	elif Input.is_action_pressed("ui_left"):
		velocity = Vector2.LEFT * bird_speed
	elif Input.is_action_pressed("ui_right"):
		velocity = Vector2.RIGHT * bird_speed
		
	position += velocity * delta
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)


func die():
	print("Bird die")
	hide()
	$AnimatedSprite2D.stop()
	$CollisionShape2D.set_deferred("disabled", true)


func start(pos = null):
	print("Bird start")
	if pos != null:
		position = pos
	show()
	$AnimatedSprite2D.animation = "bird_fly"
	$AnimatedSprite2D.play()
	$CollisionShape2D.disabled = false


# 播放一次吃的动画
func eat():
	$AnimatedSprite2D.animation = "bird_eat"
	$AnimatedSprite2D.play()


# “吃”完切换“飞”的动画
func _on_animated_sprite_2d_animation_finished():
	if $AnimatedSprite2D.animation == "bird_eat":
		$AnimatedSprite2D.animation = "bird_fly"
		$AnimatedSprite2D.play()
