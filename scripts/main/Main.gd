extends Node2D

const RockScene := preload("res://scenes/obstacles/Rock.tscn")
const ProjectileScene := preload("res://scenes/weapons/Projectile.tscn")

@onready var terrain: Terrain = $Terrain
@onready var obstacles_node: Node2D = $Obstacles
@onready var player1: Player = $Player1
@onready var player2: Player = $Player2
@onready var aim_overlay: AimOverlay = $AimOverlay
@onready var projectile_host: Node2D = $ProjectileHost
@onready var effects: Effects = $Effects
@onready var hud: Hud = $Hud

var players: Dictionary = {}
var obstacles: Array[Rock] = []
var current_player_id: String = "p1"
var wind: float = 0.0
var game_over: bool = false
var projectile: Projectile = null

var drag_active: bool = false
var drag_cur: Vector2 = Vector2.ZERO

const DEFAULT_HINT := "Toca y arrastra a tu personaje hacia atrás, luego suelta"

func _ready() -> void:
	players = {"p1": player1, "p2": player2}
	player1.player_id = "p1"
	player1.species = "dog"
	player1.body_color = Color("3b82f6")
	player1.dir = 1
	player1.terrain = terrain

	player2.player_id = "p2"
	player2.species = "cat"
	player2.body_color = Color("ef4444")
	player2.dir = -1
	player2.terrain = terrain

	hud.restart_pressed.connect(new_game)
	new_game()

func new_game() -> void:
	terrain.generate_terrain()
	_generate_obstacles()

	player1.reset(110.0)
	player2.reset(Constants.SCREEN_W - 110.0)

	current_player_id = "p1"
	game_over = false
	drag_active = false
	aim_overlay.active = false
	_clear_projectile()
	effects.clear()

	_roll_wind()
	hud.set_health("p1", player1.health)
	hud.set_health("p2", player2.health)
	hud.set_winner("")
	hud.show_restart(false)
	hud.set_hint(DEFAULT_HINT)
	_update_turn_label()

func _generate_obstacles() -> void:
	for o in obstacles:
		o.queue_free()
	obstacles.clear()

	var zone_start := Constants.SCREEN_W * 0.28
	var zone_end := Constants.SCREEN_W * 0.72
	var zone_w := zone_end - zone_start
	for i in Constants.OBSTACLE_COUNT:
		var x := zone_start + (zone_w / (Constants.OBSTACLE_COUNT - 1)) * i + (randf() * 34.0 - 17.0)
		var size: Dictionary = Constants.ROCK_SIZES[randi() % Constants.ROCK_SIZES.size()]
		var r: float = size.min + randf() * (size.max - size.min)

		var rock: Rock = RockScene.instantiate()
		obstacles_node.add_child(rock)
		rock.position = Vector2(x, terrain.height_at(x))
		rock.setup(r, size.hp)
		obstacles.append(rock)

func current_player() -> Player:
	return players[current_player_id]

func other_player() -> Player:
	return players["p2"] if current_player_id == "p1" else players["p1"]

func _roll_wind() -> void:
	wind = (randf() * 2.0 - 1.0) * 1.6
	var abs_wind := absf(wind)
	var strength := "calma"
	if abs_wind > 1.1:
		strength = "fuerte"
	elif abs_wind > 0.5:
		strength = "moderado"
	elif abs_wind > 0.15:
		strength = "suave"
	if strength == "calma":
		hud.set_wind_text("💨 Viento: calma")
	else:
		var arrow := "➡️" if wind > 0 else "⬅️"
		hud.set_wind_text("💨 Viento %s %s" % [strength, arrow])

func _update_turn_label() -> void:
	var name := "Jugador 1 🔵" if current_player_id == "p1" else "Jugador 2 🔴"
	hud.set_turn_text("Turno de " + name)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_pointer_down(get_viewport().get_mouse_position())
		else:
			_on_pointer_up()
	elif event is InputEventMouseMotion:
		_on_pointer_move(get_viewport().get_mouse_position())

func _on_pointer_down(pos: Vector2) -> void:
	if game_over or projectile != null:
		return
	var p := current_player()
	if pos.distance_to(p.anchor()) <= Constants.GRAB_RADIUS:
		drag_active = true
		drag_cur = pos
		p.is_aiming = true
		p.aim_point = pos
		aim_overlay.active = true
		aim_overlay.anchor = p.anchor()
		aim_overlay.target = pos
		aim_overlay.queue_redraw()
		hud.set_hint("Suelta para disparar")

func _on_pointer_move(pos: Vector2) -> void:
	if not drag_active:
		return
	var p := current_player()
	var anchor := p.anchor()
	var delta := pos - anchor
	if delta.length() > Constants.MAX_PULL:
		delta = delta.normalized() * Constants.MAX_PULL
	drag_cur = anchor + delta
	p.aim_point = drag_cur
	aim_overlay.anchor = anchor
	aim_overlay.target = drag_cur
	aim_overlay.queue_redraw()

func _on_pointer_up() -> void:
	if not drag_active:
		return
	var p := current_player()
	var anchor := p.anchor()
	var delta := drag_cur - anchor
	var pull_dist := delta.length()

	drag_active = false
	p.is_aiming = false
	aim_overlay.active = false
	aim_overlay.queue_redraw()

	if pull_dist < 12.0:
		hud.set_hint(DEFAULT_HINT)
		return

	p.trigger_recoil()
	_spawn_projectile(anchor, Vector2(-delta.x, -delta.y) * Constants.POWER_SCALE)
	hud.set_hint("")

func _spawn_projectile(from: Vector2, velocity: Vector2) -> void:
	projectile = ProjectileScene.instantiate()
	projectile_host.add_child(projectile)
	projectile.position = from
	projectile.velocity = velocity

func _clear_projectile() -> void:
	if projectile != null:
		projectile.queue_free()
		projectile = null

func _physics_process(_delta: float) -> void:
	if projectile == null:
		return

	projectile.step(wind)

	var other := other_player()
	var hit_other := projectile.position.distance_to(other.anchor()) < 18.0
	var hit_obstacle: Rock = null
	for o in obstacles:
		if projectile.position.distance_to(Vector2(o.position.x, o.position.y - o.radius * 0.5)) < o.radius + 6.0:
			hit_obstacle = o
			break
	var out_of_bounds := projectile.position.x < -20.0 or projectile.position.x > Constants.SCREEN_W + 20.0 or projectile.position.y > Constants.SCREEN_H + 40.0
	var hit_ground := terrain.is_below_ground(projectile.position.x, projectile.position.y)

	if hit_other or hit_ground or hit_obstacle != null:
		if hit_obstacle != null:
			_damage_obstacle(hit_obstacle, projectile.position)
		_trigger_explosion(projectile.position)
		_clear_projectile()
		_end_turn_check()
	elif out_of_bounds:
		_clear_projectile()
		_end_turn_check()

func _trigger_explosion(pos: Vector2) -> void:
	terrain.carve_crater(pos.x, pos.y, Constants.EXPLOSION_RADIUS)
	player1.apply_knockback(pos)
	player2.apply_knockback(pos)
	effects.spawn_explosion(pos.x, pos.y)
	hud.set_health("p1", player1.health)
	hud.set_health("p2", player2.health)

func _damage_obstacle(rock: Rock, hit_pos: Vector2) -> void:
	var destroyed := rock.take_hit()
	effects.spawn_debris(hit_pos.x, hit_pos.y, 5, rock.radius)
	if destroyed:
		var count := 8 + int(rock.radius / 3.0)
		effects.spawn_debris(rock.position.x, rock.position.y - rock.radius * 0.5, count, rock.radius)
		obstacles.erase(rock)
		rock.queue_free()

func _end_turn_check() -> void:
	if player1.health <= 0.0 or player2.health <= 0.0:
		game_over = true
		var winner := "Jugador 2 🔴" if player1.health <= 0.0 else "Jugador 1 🔵"
		hud.set_winner("🏆 ¡" + winner + " gana!")
		hud.show_restart(true)
		hud.set_hint("")
		return
	current_player_id = "p2" if current_player_id == "p1" else "p1"
	_roll_wind()
	_update_turn_label()
	hud.set_hint(DEFAULT_HINT)
