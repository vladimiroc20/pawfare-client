extends Node2D

const RockScene := preload("res://scenes/obstacles/Rock.tscn")
const ProjectileScene := preload("res://scenes/weapons/Projectile.tscn")
const PlayerScene := preload("res://scenes/characters/Player.tscn")

@export_range(2, 4) var player_count: int = 2
@export var biome_id: String = "" # vacío = aleatorio cada partida
@export var is_team_mode: bool = false # solo válido con player_count == 4

@onready var background: Background = $Background
@onready var terrain: Terrain = $Terrain
@onready var obstacles_node: Node2D = $Obstacles
@onready var players_host: Node2D = $PlayersHost
@onready var aim_overlay: AimOverlay = $AimOverlay
@onready var projectile_host: Node2D = $ProjectileHost
@onready var effects: Effects = $Effects
@onready var hud: Hud = $Hud

var players: Array[Player] = []
var obstacles: Array[Rock] = []
var current_turn_index: int = 0
var wind: float = 0.0
var game_over: bool = false
var projectile: Projectile = null
var current_biome: Dictionary = Biomes.LIST[0]
var elimination_order: Array[String] = []

var drag_active: bool = false
var drag_cur: Vector2 = Vector2.ZERO

const DEFAULT_HINT := "Toca y arrastra a tu personaje hacia atrás, luego suelta"

func _ready() -> void:
	if GameConfig.configured:
		player_count = GameConfig.player_count
		biome_id = GameConfig.biome_id
		is_team_mode = GameConfig.team_mode

	hud.restart_pressed.connect(new_game)
	hud.menu_pressed.connect(_on_menu_pressed)
	new_game()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func new_game() -> void:
	current_biome = Biomes.get_biome(biome_id) if biome_id != "" else Biomes.random_biome()
	background.set_biome(current_biome)
	terrain.set_biome(current_biome)
	terrain.generate_terrain()
	_generate_obstacles()
	_spawn_players()

	current_turn_index = 0
	game_over = false
	drag_active = false
	aim_overlay.active = false
	elimination_order.clear()
	_clear_projectile()
	effects.clear()

	_roll_wind()
	hud.set_biome_text(str(current_biome.icon, " ", current_biome.name))
	hud.setup_players(_player_ids(), _player_colors(), _player_labels(), _player_teams())
	for p in players:
		hud.set_health(p.player_id, p.health)
	hud.hide_podium()
	hud.show_restart(false)
	hud.set_hint(DEFAULT_HINT)
	_update_turn_label()

func _player_ids() -> Array:
	return players.map(func(p): return p.player_id)

func _player_colors() -> Array:
	return players.map(func(p): return p.body_color)

func _player_labels() -> Array:
	var n := players.size()
	return Constants.PLAYER_LABELS.slice(0, n)

func _player_teams() -> Array:
	return players.map(func(p): return p.team)

func _label_map() -> Dictionary:
	var map := {}
	for i in players.size():
		map[players[i].player_id] = Constants.PLAYER_LABELS[i % Constants.PLAYER_LABELS.size()]
	return map

func _spawn_players() -> void:
	for p in players:
		p.queue_free()
	players.clear()

	var n := clampi(player_count, Constants.MIN_PLAYERS, Constants.MAX_PLAYERS)
	var team_mode_active := is_team_mode and n == 4
	var margin := 90.0
	for i in n:
		var t := float(i) / float(n - 1) if n > 1 else 0.0
		var x := margin + (Constants.SCREEN_W - margin * 2.0) * t

		var player: Player = PlayerScene.instantiate()
		players_host.add_child(player)
		player.player_id = "p%d" % (i + 1)
		player.species = Constants.PLAYER_SPECIES[i % Constants.PLAYER_SPECIES.size()]
		player.body_color = Constants.PLAYER_COLORS[i % Constants.PLAYER_COLORS.size()]
		player.dir = 1 if x < Constants.SCREEN_W * 0.5 else -1
		player.terrain = terrain
		player.team = (i % 2) if team_mode_active else -1
		player.reset(x)
		player.eliminated.connect(_on_player_eliminated.bind(player))

		players.append(player)

func _generate_obstacles() -> void:
	for o in obstacles:
		o.queue_free()
	obstacles.clear()

	var count := clampi(Constants.OBSTACLE_COUNT + int(current_biome.get("obstacle_delta", 0)), 1, 6)
	var zone_start := Constants.SCREEN_W * 0.28
	var zone_end := Constants.SCREEN_W * 0.72
	var zone_w := zone_end - zone_start
	for i in count:
		var t := float(i) / float(count - 1) if count > 1 else 0.5
		var x := zone_start + zone_w * t + (randf() * 34.0 - 17.0)
		var size: Dictionary = Constants.ROCK_SIZES[randi() % Constants.ROCK_SIZES.size()]
		var r: float = size.min + randf() * (size.max - size.min)

		var rock: Rock = RockScene.instantiate()
		obstacles_node.add_child(rock)
		rock.position = Vector2(x, terrain.height_at(x))
		rock.apply_palette(current_biome.rock, current_biome.rock_accent)
		rock.setup(r, size.hp)
		obstacles.append(rock)

func current_player() -> Player:
	return players[current_turn_index]

func _on_player_eliminated(p: Player) -> void:
	elimination_order.append(p.player_id)
	effects.spawn_ko_burst(p.position.x, p.anchor().y)

func _roll_wind() -> void:
	wind = (randf() * 2.0 - 1.0) * 1.6 * float(current_biome.get("wind_scale", 1.0))
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
	hud.set_turn_text("Turno de " + Constants.PLAYER_LABELS[current_turn_index % Constants.PLAYER_LABELS.size()])

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

	var shooter := current_player()
	var hit_other := false
	for p in players:
		if p == shooter or p.health <= 0.0:
			continue
		if projectile.position.distance_to(p.anchor()) < 18.0:
			hit_other = true
			break

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
	for p in players:
		p.apply_knockback(pos)
		hud.set_health(p.player_id, p.health)
	effects.spawn_explosion(pos.x, pos.y)

func _damage_obstacle(rock: Rock, hit_pos: Vector2) -> void:
	var destroyed := rock.take_hit()
	effects.spawn_debris(hit_pos.x, hit_pos.y, 5, rock.radius)
	if destroyed:
		var count := 8 + int(rock.radius / 3.0)
		effects.spawn_debris(rock.position.x, rock.position.y - rock.radius * 0.5, count, rock.radius)
		obstacles.erase(rock)
		rock.queue_free()

func _end_turn_check() -> void:
	if _is_match_over():
		game_over = true
		hud.show_podium(_build_ranking(), _label_map())
		hud.show_restart(true)
		hud.set_hint("")
		return

	var n := players.size()
	for i in n:
		current_turn_index = (current_turn_index + 1) % n
		if players[current_turn_index].health > 0.0:
			break

	_roll_wind()
	_update_turn_label()
	hud.set_hint(DEFAULT_HINT)

func _is_match_over() -> bool:
	var team_mode_active := is_team_mode and players.size() == 4
	if team_mode_active:
		var team_a_alive := players.any(func(p): return p.team == 0 and p.health > 0.0)
		var team_b_alive := players.any(func(p): return p.team == 1 and p.health > 0.0)
		return not (team_a_alive and team_b_alive)
	var alive := players.filter(func(p): return p.health > 0.0)
	return alive.size() <= 1

func _build_ranking() -> Array:
	var team_mode_active := is_team_mode and players.size() == 4
	if team_mode_active:
		return _build_team_ranking()
	return _build_ffa_ranking()

func _build_ffa_ranking() -> Array:
	var ranking: Array = []
	var alive := players.filter(func(p): return p.health > 0.0)
	var place := 1
	if alive.size() == 1:
		ranking.append({"place": place, "ids": [alive[0].player_id]})
		place += 1
	var order := elimination_order.duplicate()
	order.reverse()
	for id in order:
		ranking.append({"place": place, "ids": [id]})
		place += 1
	return ranking

func _build_team_ranking() -> Array:
	var team_a_alive := players.any(func(p): return p.team == 0 and p.health > 0.0)
	var team_b_alive := players.any(func(p): return p.team == 1 and p.health > 0.0)
	if team_a_alive == team_b_alive:
		return []
	var winning_team := 0 if team_a_alive else 1
	var winners := players.filter(func(p): return p.team == winning_team)
	var losers := players.filter(func(p): return p.team != winning_team)
	return [
		{"place": 1, "ids": winners.map(func(p): return p.player_id)},
		{"place": 2, "ids": losers.map(func(p): return p.player_id)},
	]
