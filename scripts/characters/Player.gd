extends Node2D
class_name Player

signal eliminated

@export var species: String = "dog" # "dog", "cat", "rabbit", "panda" or "fox"
@export var body_color: Color = Color("3b82f6")
@export var dir: int = 1
@export var player_id: String = "p1"

var terrain: Terrain
var team: int = -1 # -1 = sin equipo (todos contra todos), 0/1 = equipo A/B
var weapon_id: String = "bazooka"

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

func is_down() -> bool:
	return health <= 0.0

func take_damage(amount: float) -> void:
	var was_alive := health > 0.0
	health = maxf(0.0, health - amount)
	if was_alive and health <= 0.0:
		eliminated.emit()

func apply_knockback(from: Vector2, explosion_radius: float = Constants.EXPLOSION_RADIUS, damage: float = Constants.DAMAGE) -> void:
	if health <= 0.0:
		return
	var dx := position.x - from.x
	var dy := anchor().y - from.y
	var d := Vector2(dx, dy).length()
	if d == 0.0:
		d = 1.0
	var dmg_range := explosion_radius + 20.0
	if d < dmg_range:
		var falloff := 1.0 - minf(d / dmg_range, 1.0)
		take_damage(damage * (0.4 + 0.6 * falloff))
		var nx := dx / d
		var ny := dy / d
		knock_vx = nx * Constants.KNOCKBACK_FORCE * (0.5 + falloff)
		knock_vy = ny * Constants.KNOCKBACK_FORCE * (0.5 + falloff) - 2.5 * falloff
		airborne = true

func _physics_process(_delta: float) -> void:
	_anim_time += 1.0
	recoil = maxf(0.0, recoil - 0.045)
	if not airborne and terrain and position.y < terrain.height_at(position.x) - 1.0:
		# El terreno bajo los pies pudo desaparecer sin que este jugador recibiera
		# el golpe (p. ej. el túnel del Perforador pasa lejos del punto de impacto
		# final) — sin esto, se queda flotando sobre el cráter en vez de caer.
		airborne = true
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
	var down := is_down()
	var bob := 0.0 if down else sin(_anim_time * 0.02 + _phase) * 1.6
	var kick := recoil * 6.0 * -dir
	var squash := 1.0 - recoil * 0.12
	var body_scale := Vector2(1.0 + recoil * 0.08, squash)
	var rot := knock_vx * 0.03 if airborne else 0.0
	if down:
		rot = deg_to_rad(90.0) * dir

	var body_xform := Transform2D(rot, Vector2(kick, bob))
	body_xform.x *= body_scale.x
	body_xform.y *= body_scale.y
	draw_set_transform_matrix(body_xform)

	var display_color := body_color.lerp(Color(0.55, 0.55, 0.58), 0.75) if down else body_color
	var light := display_color.lightened(0.3)
	var dark := display_color.darkened(0.3)

	DrawUtils.draw_soft_blob(self, Vector2(0, 3), 19, 6, Color(0, 0, 0, 0.32), 3)
	match species:
		"rabbit":
			_draw_round_tail()
		"fox":
			_draw_fox_tail(dark)
		_:
			_draw_swoosh_tail(dark)

	# Patas con contorno y una almohadilla clara — antes eran dos manchas planas sin
	# ningún borde, aquí apenas se asoman bajo el cuerpo como en la referencia.
	for lx in [-7.0 * dir, 7.0 * dir]:
		var leg := DrawUtils.ellipse_points(Vector2(lx, 1), 6.5, 5.5)
		draw_colored_polygon(leg, dark)
		_outline_shape(leg, 2.0)
		var pad := DrawUtils.ellipse_points(Vector2(lx, 4), 3.6, 2.2)
		draw_colored_polygon(pad, Color(0.98, 0.96, 0.92))

	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(0, -14), 17, 16), display_color)
	# Referencia (Wild Ones): el estilo real es plano/gráfico, no pintado con degradado
	# suave — el "pop" viene del contorno grueso y los bloques de color, no de sombras
	# difusas. Se deja solo un toque mínimo de volumen, muy por debajo de lo que había.
	DrawUtils.draw_soft_blob(self, Vector2(4 * dir, -8), 13, 11, Color(dark.r, dark.g, dark.b, 0.12), 2)
	DrawUtils.draw_soft_blob(self, Vector2(-4 * dir, -20), 10, 9, Color(light.r, light.g, light.b, 0.3), 2)
	var outline := DrawUtils.ellipse_points(Vector2(0, -14), 17, 16)
	outline.append(outline[0])
	draw_polyline(outline, dark, 3.2)

	# Panza/pecho clara grande y bien delimitada (con su propio contorno) — no un
	# brillo sutil, es un bloque de color propio, como en la referencia.
	var belly := DrawUtils.ellipse_points(Vector2(2 * dir, -9), 11, 10)
	draw_colored_polygon(belly, Color(0.98, 0.96, 0.92))
	var belly_outline := belly.duplicate()
	belly_outline.append(belly_outline[0])
	draw_polyline(belly_outline, dark, 2.0)

	match species:
		"cat":
			_draw_cat_ears(dark)
		"rabbit":
			_draw_rabbit_ears(dark)
		"panda":
			_draw_panda_ears()
		"fox":
			_draw_fox_ears(dark)
		_:
			_draw_dog_ears(dark)

	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(10 * dir, -11), 6, 5), light)
	draw_circle(Vector2(14 * dir, -12), 1.6, Color.BLACK)

	if species == "panda":
		draw_colored_polygon(DrawUtils.ellipse_points(Vector2(6 * dir, -18), 7.2, 7.2), Color(0.08, 0.08, 0.08))
	# Ojo más grande y con un brillo puntual — el "toy eye" glossy que vende lo tierno/coleccionable.
	draw_circle(Vector2(6 * dir, -18), 5.2, Color.WHITE)
	if down:
		var ex := 6.0 * dir
		var ey := -18.0
		draw_line(Vector2(ex - 2.6, ey - 2.6), Vector2(ex + 2.6, ey + 2.6), Color(0.067, 0.067, 0.067), 1.8)
		draw_line(Vector2(ex - 2.6, ey + 2.6), Vector2(ex + 2.6, ey - 2.6), Color(0.067, 0.067, 0.067), 1.8)
	else:
		draw_circle(Vector2(7.5 * dir, -18), 2.7, Color(0.067, 0.067, 0.067))
		draw_circle(Vector2(8.3 * dir, -19.3), 0.9, Color(1, 1, 1, 0.85))
		# Ceja gruesa y angulada — le da carácter "decidido" a la cara, que antes se
		# quedaba neutra con solo ojo + nariz (referencia: cejas marcadas + boca visibles).
		draw_line(Vector2(2.5 * dir, -24.5), Vector2(9.5 * dir, -22.0), Color(0.067, 0.067, 0.067), 2.4)
		# Boca pequeña bajo el hocico.
		var mouth := DrawUtils.quad_bezier_points(Vector2(8 * dir, -7), Vector2(11 * dir, -5), Vector2(13 * dir, -7.5), 6)
		draw_polyline(mouth, Color(0.067, 0.067, 0.067), 1.6)

	if not down:
		_draw_weapon(body_xform, display_color)

	draw_set_transform_matrix(Transform2D.IDENTITY)

const MARK_OUTLINE := Color(0.086, 0.09, 0.106)

## Cierra un contorno grueso alrededor de un polígono ya dibujado — mismo
## lenguaje "sticker" que el cuerpo y las armas, aplicado a orejas/colas.
func _outline_shape(pts: PackedVector2Array, width: float = 2.2) -> void:
	var closed := pts.duplicate()
	closed.append(closed[0])
	draw_polyline(closed, MARK_OUTLINE, width)

func _draw_swoosh_tail(dark: Color) -> void:
	var p0 := Vector2(-14 * dir, -6)
	var ctrl := Vector2(-26 * dir, -2)
	var p1 := Vector2(-22 * dir, -20)
	draw_polyline(DrawUtils.quad_bezier_points(p0, ctrl, p1, 12), dark, 6.0, true)
	draw_polyline(DrawUtils.quad_bezier_points(p0, ctrl, p1, 12), MARK_OUTLINE, 6.8, true)
	draw_polyline(DrawUtils.quad_bezier_points(p0, ctrl, p1, 12), dark, 6.0, true)

func _draw_round_tail() -> void:
	var pts := DrawUtils.ellipse_points(Vector2(-17 * dir, -6), 5, 5)
	draw_colored_polygon(pts, Color(0.98, 0.96, 0.92))
	_outline_shape(pts, 2.0)

func _draw_fox_tail(dark: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(-12 * dir, -10), Vector2(-32 * dir, -16), Vector2(-27 * dir, 4), Vector2(-14 * dir, 1)
	])
	draw_colored_polygon(pts, dark)
	_outline_shape(pts, 2.2)
	var tip := DrawUtils.ellipse_points(Vector2(-29 * dir, -8), 5, 5)
	draw_colored_polygon(tip, Color(0.98, 0.96, 0.92))
	_outline_shape(tip, 1.8)

func _draw_dog_ears(dark: Color) -> void:
	var l := DrawUtils.ellipse_points(Vector2(-11 * dir, -24), 6, 10, -0.3 * dir)
	var r := DrawUtils.ellipse_points(Vector2(11 * dir, -24), 6, 10, 0.3 * dir)
	draw_colored_polygon(l, dark)
	draw_colored_polygon(r, dark)
	_outline_shape(l)
	_outline_shape(r)
	# Manchas repartidas por el cuerpo (parche del ojo + lomo + costado) — un patrón
	# con más cobertura, no solo una marca aislada.
	var patch := DrawUtils.ellipse_points(Vector2(9 * dir, -18), 7, 8, 0.15 * dir)
	draw_colored_polygon(patch, dark)
	_outline_shape(patch, 2.0)
	var back_spot := DrawUtils.ellipse_points(Vector2(-9 * dir, -19), 6, 7, -0.2 * dir)
	draw_colored_polygon(back_spot, dark)
	_outline_shape(back_spot, 2.0)
	var flank_spot := DrawUtils.ellipse_points(Vector2(-4 * dir, -3), 5, 4.5)
	draw_colored_polygon(flank_spot, dark)
	_outline_shape(flank_spot, 1.8)

func _draw_cat_ears(dark: Color) -> void:
	var l := PackedVector2Array([Vector2(-14 * dir, -22), Vector2(-8 * dir, -34), Vector2(-3 * dir, -22)])
	var r := PackedVector2Array([Vector2(3 * dir, -22), Vector2(8 * dir, -34), Vector2(14 * dir, -22)])
	draw_colored_polygon(l, dark)
	draw_colored_polygon(r, dark)
	_outline_shape(l)
	_outline_shape(r)
	# Rayas "atigradas" en la frente y a lo largo del lomo — cobertura de cuerpo
	# completo en vez de una sola marca en la cabeza.
	for sx in [-5.0 * dir, 0.0, 5.0 * dir]:
		var stripe := DrawUtils.quad_bezier_points(Vector2(sx - 2, -27), Vector2(sx, -31), Vector2(sx + 2, -27), 6)
		draw_polyline(stripe, dark, 2.2)
	for sy in [-21.0, -13.0, -5.0]:
		var back_stripe := DrawUtils.quad_bezier_points(
			Vector2(-14 * dir, sy - 3), Vector2(-10 * dir, sy), Vector2(-14 * dir, sy + 3), 6
		)
		draw_polyline(back_stripe, dark, 2.2)

func _draw_rabbit_ears(dark: Color) -> void:
	var l := DrawUtils.ellipse_points(Vector2(-6 * dir, -32), 4, 15, -0.12 * dir)
	var r := DrawUtils.ellipse_points(Vector2(6 * dir, -32), 4, 15, 0.12 * dir)
	draw_colored_polygon(l, dark)
	draw_colored_polygon(r, dark)
	_outline_shape(l)
	_outline_shape(r)
	# Interior de oreja rosado y opaco (antes era un blanco translúcido apenas visible).
	var inner_color := Color(0.98, 0.75, 0.8)
	var li := DrawUtils.ellipse_points(Vector2(-6 * dir, -32), 2, 11, -0.12 * dir)
	var ri := DrawUtils.ellipse_points(Vector2(6 * dir, -32), 2, 11, 0.12 * dir)
	draw_colored_polygon(li, inner_color)
	draw_colored_polygon(ri, inner_color)
	# Mejillas sonrosadas y una motita en el lomo — más cobertura que solo las orejas.
	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(9 * dir, -9), 3.4, 2.6), Color(0.98, 0.75, 0.8, 0.65))
	var back_tuft := DrawUtils.ellipse_points(Vector2(-9 * dir, -19), 5, 5.5)
	draw_colored_polygon(back_tuft, Color(0.98, 0.96, 0.92))
	_outline_shape(back_tuft, 1.8)

func _draw_panda_ears() -> void:
	var black := Color(0.08, 0.08, 0.08)
	var l := DrawUtils.ellipse_points(Vector2(-12 * dir, -26), 7, 7)
	var r := DrawUtils.ellipse_points(Vector2(12 * dir, -26), 7, 7)
	draw_colored_polygon(l, black)
	draw_colored_polygon(r, black)
	_outline_shape(l)
	_outline_shape(r)
	# "Montura" negra sobre el lomo/hombro — los pandas reales también son negros ahí,
	# no solo en orejas y ojos, así que es más cobertura sin inventar nada ajeno.
	var saddle := DrawUtils.ellipse_points(Vector2(-8 * dir, -20), 8, 10, -0.15 * dir)
	draw_colored_polygon(saddle, black)
	_outline_shape(saddle, 2.0)

func _draw_fox_ears(dark: Color) -> void:
	var l := PackedVector2Array([Vector2(-15 * dir, -19), Vector2(-9 * dir, -33), Vector2(-2 * dir, -20)])
	var r := PackedVector2Array([Vector2(2 * dir, -20), Vector2(9 * dir, -33), Vector2(15 * dir, -19)])
	draw_colored_polygon(l, dark)
	draw_colored_polygon(r, dark)
	_outline_shape(l)
	_outline_shape(r)
	# Antifaz oscuro alrededor del ojo + puntas de oreja oscuras + mota en el lomo —
	# más cobertura que un solo antifaz.
	var mask := DrawUtils.ellipse_points(Vector2(8 * dir, -17), 8, 6, 0.1 * dir)
	draw_colored_polygon(mask, dark)
	_outline_shape(mask, 2.0)
	var tip_l := PackedVector2Array([Vector2(-11 * dir, -28), Vector2(-9 * dir, -34), Vector2(-6 * dir, -27)])
	var tip_r := PackedVector2Array([Vector2(6 * dir, -27), Vector2(9 * dir, -34), Vector2(11 * dir, -28)])
	draw_colored_polygon(tip_l, Color(0.08, 0.08, 0.08))
	draw_colored_polygon(tip_r, Color(0.08, 0.08, 0.08))
	var back_spot := DrawUtils.ellipse_points(Vector2(-9 * dir, -19), 6, 7, -0.2 * dir)
	draw_colored_polygon(back_spot, dark)
	_outline_shape(back_spot, 2.0)

func _draw_weapon(body_xform: Transform2D, display_color: Color) -> void:
	var weapon_angle := _weapon_angle()
	var barrel_kick := recoil * 8.0
	var weapon_local := Transform2D(weapon_angle, Vector2(-2 * dir, -20))
	weapon_local = weapon_local * Transform2D(0.0, Vector2(0, barrel_kick))
	draw_set_transform_matrix(body_xform * weapon_local)

	match weapon_id:
		"cluster":
			_draw_weapon_cluster()
		"bouncer":
			_draw_weapon_bouncer()
		"piercer":
			_draw_weapon_piercer()
		_:
			_draw_weapon_bazooka()

	# Pata sujetando el agarre del arma — en la referencia el arma siempre se ve
	# tomada con las patas, no flotando sola frente al personaje.
	var paw := DrawUtils.ellipse_points(Vector2(0, -2), 5.8, 4.6)
	draw_colored_polygon(paw, display_color)
	_outline_shape(paw, 2.0)

	if recoil > 0.05:
		draw_circle(Vector2(0, -22), 6.0 + recoil * 6.0, Color(1.0, 0.706, 0.235, recoil))

	draw_set_transform_matrix(body_xform)

## Armas robustas y redondeadas tipo juguete (cañón gordo + tapa/boca de color
## vivo + banda de agarre) en vez de tubos metálicos de esquina dura — mismo
## lenguaje visual que Wild Ones (chibi/juguete, dibujado a mano, no fotorrealista),
## con diseños propios (ver CLAUDE.md maestro, regla de propiedad intelectual).
const WEAPON_OUTLINE := Color(0.086, 0.09, 0.106)

func _draw_weapon_bazooka() -> void:
	DrawUtils.draw_capsule(self, Vector2(0, 6), Vector2(0, -18), 9.0, Color("52606d"), WEAPON_OUTLINE)
	draw_circle(Vector2(0, -18), 7.0, Color("f59e0b"))
	draw_arc(Vector2(0, -18), 7.0, 0.0, TAU, 16, WEAPON_OUTLINE, 2.0)
	draw_circle(Vector2(0, -18), 2.8, Color("374151"))
	DrawUtils.draw_capsule(self, Vector2(-7, -2), Vector2(7, -2), 3.4, Color("374151"), WEAPON_OUTLINE)

func _draw_weapon_cluster() -> void:
	DrawUtils.draw_capsule(self, Vector2(0, 6), Vector2(0, -16), 11.0, Color("52606d"), WEAPON_OUTLINE)
	for bx in [-4.0, 0.0, 4.0]:
		var by := -18.0 if bx != 0.0 else -20.0
		draw_circle(Vector2(bx, by), 3.0, Color("dc2626"))
		draw_arc(Vector2(bx, by), 3.0, 0.0, TAU, 10, WEAPON_OUTLINE, 1.3)
	DrawUtils.draw_capsule(self, Vector2(-7, -2), Vector2(7, -2), 3.4, Color("f59e0b"), WEAPON_OUTLINE)

func _draw_weapon_bouncer() -> void:
	DrawUtils.draw_capsule(self, Vector2(0, 4), Vector2(0, -13), 9.0, Color("52606d"), WEAPON_OUTLINE)
	draw_circle(Vector2(0, -18), 6.8, Color("65a30d"))
	draw_arc(Vector2(0, -18), 6.8, 0.0, TAU, 16, WEAPON_OUTLINE, 2.0)
	draw_circle(Vector2(-2.2, -20.2), 2.3, Color(1, 1, 1, 0.55))
	DrawUtils.draw_capsule(self, Vector2(-6, -1), Vector2(6, -1), 3.2, Color("374151"), WEAPON_OUTLINE)

func _draw_weapon_piercer() -> void:
	DrawUtils.draw_capsule(self, Vector2(0, 6), Vector2(0, -30), 5.4, Color("3f3f46"), WEAPON_OUTLINE)
	draw_circle(Vector2(0, -30), 3.6, Color("fde047"))
	draw_arc(Vector2(0, -30), 3.6, 0.0, TAU, 12, WEAPON_OUTLINE, 1.6)
	draw_circle(Vector2(0, -30), 1.5, Color("3f3f46"))
	DrawUtils.draw_capsule(self, Vector2(-5, -2), Vector2(5, -2), 3.0, Color("18181b"), WEAPON_OUTLINE)
