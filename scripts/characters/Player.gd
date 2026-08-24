extends Node2D
class_name Player

@export var species: String = "dog" # "dog" or "cat"
@export var body_color: Color = Color("3b82f6")
@export var dir: int = 1
@export var player_id: String = "p1"

var terrain: Terrain

var health: float = 100.0
var knock_vx: float = 0.0
var knock_vy: float = 0.0
var airborne: bool = false
var recoil: float = 0.0
var is_aiming: bool = false
var aim_point: Vector2 = Vector2.ZERO

var _anim_time: float = 0.0
var _phase: float = 0.0

func _ready() -> void:
	_phase = 2.4 if player_id == "p2" else 0.0

func reset(spawn_x: float) -> void:
	position.x = spawn_x
	health = 100.0
	knock_vx = 0.0
	knock_vy = 0.0
	airborne = false
	recoil = 0.0
	is_aiming = false
	if terrain:
		position.y = terrain.height_at(spawn_x)

func anchor() -> Vector2:
	return position + Vector2(0, -14)

func trigger_recoil() -> void:
	recoil = 1.0

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)

func apply_knockback(from: Vector2) -> void:
	if health <= 0.0:
		return
	var dx := position.x - from.x
	var dy := anchor().y - from.y
	var d := Vector2(dx, dy).length()
	if d == 0.0:
		d = 1.0
	var dmg_range := Constants.DAMAGE_RANGE
	if d < dmg_range:
		var falloff := 1.0 - minf(d / dmg_range, 1.0)
		take_damage(Constants.DAMAGE * (0.4 + 0.6 * falloff))
		var nx := dx / d
		var ny := dy / d
		knock_vx = nx * Constants.KNOCKBACK_FORCE * (0.5 + falloff)
		knock_vy = ny * Constants.KNOCKBACK_FORCE * (0.5 + falloff) - 2.5 * falloff
		airborne = true

func _physics_process(_delta: float) -> void:
	_anim_time += 1.0
	recoil = maxf(0.0, recoil - 0.045)
	if airborne:
		_update_knockback()
	queue_redraw()

func _update_knockback() -> void:
	knock_vy += Constants.KNOCK_GRAVITY
	position.x += knock_vx
	position.y += knock_vy
	position.x = clampf(position.x, 18.0, Constants.SCREEN_W - 18.0)

	var ground_y := terrain.height_at(position.x)
	if position.y >= ground_y:
		position.y = ground_y
		if absf(knock_vy) > 3.0:
			knock_vy *= -0.28
			knock_vx *= 0.5
		else:
			airborne = false
			knock_vx = 0.0
			knock_vy = 0.0

func _weapon_angle() -> float:
	if is_aiming:
		var dx := aim_point.x - position.x
		var dy := aim_point.y - anchor().y
		return atan2(-dx, dy)
	return (-0.5 * dir) + sin(_anim_time * 0.015 + _phase) * 0.045

func _draw() -> void:
	var bob := sin(_anim_time * 0.02 + _phase) * 1.6
	var kick := recoil * 6.0 * -dir
	var squash := 1.0 - recoil * 0.12
	var body_scale := Vector2(1.0 + recoil * 0.08, squash)
	var rot := knock_vx * 0.03 if airborne else 0.0

	var body_xform := Transform2D(rot, Vector2(kick, bob))
	body_xform.x *= body_scale.x
	body_xform.y *= body_scale.y
	draw_set_transform_matrix(body_xform)

	var light := body_color.lightened(0.3)
	var dark := body_color.darkened(0.3)

	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(0, 3), 18, 5), Color(0, 0, 0, 0.25))
	_draw_tail(dark)

	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(-7 * dir, 0), 6, 5), dark)
	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(7 * dir, 0), 6, 5), dark)

	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(0, -14), 17, 16), body_color)
	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(-4 * dir, -20), 10, 9), Color(light.r, light.g, light.b, 0.5))
	var outline := DrawUtils.ellipse_points(Vector2(0, -14), 17, 16)
	outline.append(outline[0])
	draw_polyline(outline, dark, 2.0)

	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(2 * dir, -9), 9, 8), Color(1, 1, 1, 0.55))

	if species == "dog":
		_draw_dog_ears(dark)
	else:
		_draw_cat_ears(dark)

	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(10 * dir, -11), 6, 5), light)
	draw_circle(Vector2(14 * dir, -12), 1.6, Color.BLACK)

	draw_circle(Vector2(6 * dir, -18), 4.5, Color.WHITE)
	draw_circle(Vector2(7.5 * dir, -18), 2.3, Color(0.067, 0.067, 0.067))

	_draw_weapon(body_xform)

	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_tail(dark: Color) -> void:
	var p0 := Vector2(-14 * dir, -6)
	var ctrl := Vector2(-26 * dir, -2)
	var p1 := Vector2(-22 * dir, -20)
	draw_polyline(DrawUtils.quad_bezier_points(p0, ctrl, p1, 12), dark, 6.0, true)

func _draw_dog_ears(dark: Color) -> void:
	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(-11 * dir, -24), 6, 10, -0.3 * dir), dark)
	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(11 * dir, -24), 6, 10, 0.3 * dir), dark)

func _draw_cat_ears(dark: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14 * dir, -22), Vector2(-8 * dir, -34), Vector2(-3 * dir, -22)
	]), dark)
	draw_colored_polygon(PackedVector2Array([
		Vector2(3 * dir, -22), Vector2(8 * dir, -34), Vector2(14 * dir, -22)
	]), dark)

func _draw_weapon(body_xform: Transform2D) -> void:
	var weapon_angle := _weapon_angle()
	var barrel_kick := recoil * 8.0
	var weapon_local := Transform2D(weapon_angle, Vector2(-2 * dir, -20))
	weapon_local = weapon_local * Transform2D(0.0, Vector2(0, barrel_kick))
	draw_set_transform_matrix(body_xform * weapon_local)

	draw_rect(Rect2(-4, -18, 8, 26), Color("4b5563"))
	draw_rect(Rect2(-6, -20, 12, 6), Color("374151"))
	draw_rect(Rect2(-3, 4, 6, 5), Color("f59e0b"))
	if recoil > 0.05:
		draw_circle(Vector2(0, -22), 6.0 + recoil * 6.0, Color(1.0, 0.706, 0.235, recoil))

	draw_set_transform_matrix(body_xform)
