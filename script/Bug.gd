extends RigidBody2D

const object_type = "Bug"
var bug_id = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


func born(id = 0, pos = null):
	bug_id = id
	if pos != null:
		position = pos
	show()
	$AnimatedSprite2D.play()
	$CollisionShape2D.disabled = false


func die():
	hide()
	$AnimatedSprite2D.stop()
	$CollisionShape2D.set_deferred("disabled", true)
