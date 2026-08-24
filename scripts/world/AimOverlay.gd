extends Node2D
class_name AimOverlay

var active: bool = false
var anchor: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2.ZERO

func _draw() -> void:
	if not active:
		return
	var delta := target - anchor
	var pull_dist := delta.length()
	if pull_dist < 12.0:
		return

	var vx := -delta.x * Constants.POWER_SCALE
	var vy := -delta.y * Constants.POWER_SCALE
	var steps := [10.0, 20.0, 30.0]
	for i in steps.size():
		var t: float = steps[i]
		var p := anchor + Vector2(vx * t, vy * t + 0.5 * Constants.GRAVITY * t * t)
		draw_circle(p, 5.0 - i, Color(1, 1, 1, 0.85 - i * 0.2))

	draw_line(anchor, target, Color(1, 1, 1, 0.85), 4.0)
	draw_circle(target, 10.0, Color("fbbf24"))
