extends Node2D

const RockScene := preload("res://scenes/obstacles/Rock.tscn")
const PlayerScene := preload("res://scenes/characters/Player.tscn")

@onready var background: Background = $Background
@onready var terrain: Terrain = $Terrain
@onready var obstacles_node: Node2D = $Obstacles
@onready var players_host: Node2D = $PlayersHost
@onready var aim_overlay: AimOverlay = $AimOverlay
@onready var projectile_host: Node2D = $ProjectileHost
@onready var effects: Effects = $Effects
@onready var hud: Hud = $Hud

var player_nodes: Dictionary = {}
var rock_nodes: Array[Rock] = []
var current_biome_id: String = ""
var last_health: Dictionary = {}
var last_heights: PackedFloat32Array = PackedFloat32Array()
var known_player_ids: Array = []

var last_state: Dictionary = {}
var my_player_id: String = ""
var game_over_shown: bool = false
var selected_weapon_id: String = Weapons.DEFAULT_ID

var drag_active: bool = false
var drag_cur: Vector2 = Vector2.ZERO

const ProjectileScene := preload("res://scenes/weapons/Projectile.tscn")
const MAX_PREDICTION_TICKS := 240

var known_shot_seq: int = -1
var predicting_shot: bool = false
var pending_final_state: Dictionary = {}
var predicted_projectile: Projectile = null
var predicted_weapon: Dictionary = Weapons.get_weapon(Weapons.DEFAULT_ID)
var predicted_shooter_id: String = ""
var predicted_wind: float = 0.0
var prediction_ticks: int = 0

func _ready() -> void:
	my_player_id = NetworkClient.player_id
	NetworkClient.state_updated.connect(_on_state_updated)
	NetworkClient.action_failed.connect(func(msg: String): hud.set_hint("Error: " + msg))
	hud.restart_pressed.connect(_on_menu_pressed)
	hud.menu_pressed.connect(_on_menu_pressed)
	hud.weapon_selected.connect(_on_weapon_selected)
	hud.show_restart(false)
	hud.hide_podium()
	hud.set_weapon_row_visible(true)

	if not NetworkClient.last_state.is_empty():
		_on_state_updated(NetworkClient.last_state)

func _exit_tree() -> void:
	NetworkClient.leave_match()

func _on_weapon_selected(id: String) -> void:
	selected_weapon_id = id
	if player_nodes.has(my_player_id):
		player_nodes[my_player_id].weapon_id = id

func _on_menu_pressed() -> void:
	NetworkClient.leave_match()
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _on_state_updated(state: Dictionary) -> void:
	if last_state.is_empty():
		known_shot_seq = int(state.get("shotSeq", 0))
		_apply_state(state, false)
		return

	if predicting_shot:
		pending_final_state = state
		return

	var shot_seq: int = int(state.get("shotSeq", 0))
	var last_shot = state.get("lastShot")
	if shot_seq != known_shot_seq and last_shot != null and player_nodes.has(String(last_shot.shooterId)):
		_start_shot_prediction(last_shot, state)
	else:
		known_shot_seq = shot_seq
		_apply_state(state, false)

func _apply_state(state: Dictionary, skip_impact_fx: bool) -> void:
	last_state = state

	if state.biomeId != current_biome_id:
		current_biome_id = state.biomeId
		var biome: Dictionary = Biomes.get_biome(current_biome_id)
		background.set_biome(biome)
		terrain.set_biome(biome)
		hud.set_biome_text(str(biome.icon, " ", biome.name))

	var new_heights: Array = state.terrainHeights
	if not skip_impact_fx and last_heights.size() == new_heights.size() and not last_heights.is_empty():
		_spawn_impact_fx_if_changed(new_heights)
	last_heights = PackedFloat32Array(new_heights)
	terrain.set_heights(new_heights)

	_sync_obstacles(state.obstacles)
	_sync_players(state.players)
	hud.set_wind_text(_wind_text(state.wind))

	if state.phase == "waiting":
		hud.set_turn_text("Esperando jugadores...")
		hud.set_hint("%d / %d jugadores conectados" % [state.players.size(), state.playerCount])
	elif state.gameOver:
		hud.set_hint("")
		if not game_over_shown:
			game_over_shown = true
			_show_podium(state)
	else:
		var current_id: String = state.turnOrder[state.currentTurnIndex]
		hud.set_turn_text("Turno de " + _label_for(state, current_id))
		hud.set_hint("Tu turno: arrastra para disparar" if current_id == my_player_id else "Esperando al rival...")

func _start_shot_prediction(shot: Dictionary, final_state: Dictionary) -> void:
	var shooter_id := String(shot.shooterId)
	var shooter_node: Player = player_nodes[shooter_id]

	predicting_shot = true
	pending_final_state = final_state
	predicted_weapon = Weapons.get_weapon(String(shot.weaponId))
	predicted_shooter_id = shooter_id
	predicted_wind = float(shot.wind)
	prediction_ticks = 0

	predicted_projectile = ProjectileScene.instantiate()
	projectile_host.add_child(predicted_projectile)
	predicted_projectile.position = shooter_node.anchor()
	predicted_projectile.velocity = Vector2(-float(shot.dx), -float(shot.dy)) * Constants.POWER_SCALE
	predicted_projectile.bounces_left = int(predicted_weapon.bounces)
	predicted_projectile.tunnel_ticks_left = int(predicted_weapon.tunnel_ticks)
	predicted_projectile.gravity_scale = 0.15 if int(predicted_weapon.tunnel_ticks) > 0 else 1.0
	predicted_projectile.weapon_id = String(predicted_weapon.id)

func _physics_process(_delta: float) -> void:
	if not predicting_shot or predicted_projectile == null:
		return

	prediction_ticks += 1
	predicted_projectile.step(predicted_wind)

	var pos := predicted_projectile.position
	var hit_other := false
	for id in player_nodes:
		if id == predicted_shooter_id:
			continue
		var node: Player = player_nodes[id]
		if node.health <= 0.0:
			continue
		if pos.distance_to(node.anchor()) < 18.0:
			hit_other = true
			break

	var hit_obstacle := false
	for r in rock_nodes:
		if pos.distance_to(Vector2(r.position.x, r.position.y - r.radius * 0.5)) < r.radius + 6.0:
			hit_obstacle = true
			break

	var out_of_bounds := pos.x < -20.0 or pos.x > Constants.SCREEN_W + 20.0 or pos.y > Constants.SCREEN_H + 40.0
	var hit_ground := terrain.is_below_ground(pos.x, pos.y)

	if hit_ground and not hit_other and not hit_obstacle and predicted_projectile.bounces_left > 0:
		predicted_projectile.bounces_left -= 1
		predicted_projectile.position.y = terrain.height_at(pos.x) - 1.0
		predicted_projectile.velocity.y = -predicted_projectile.velocity.y * 0.55
		predicted_projectile.velocity.x *= 0.85
		return

	if hit_ground and not hit_other and not hit_obstacle and predicted_projectile.tunnel_ticks_left > 0:
		predicted_projectile.tunnel_ticks_left -= 1
		terrain.carve_crater(pos.x, pos.y, float(predicted_weapon.tunnel_radius))
		return

	if hit_other or hit_ground or hit_obstacle:
		effects.spawn_explosion(pos.x, pos.y)
		_finish_shot_prediction()
	elif out_of_bounds or prediction_ticks > MAX_PREDICTION_TICKS:
		_finish_shot_prediction()

func _finish_shot_prediction() -> void:
	if predicted_projectile != null:
		predicted_projectile.queue_free()
		predicted_projectile = null
	predicting_shot = false

	var state := pending_final_state
	pending_final_state = {}
	known_shot_seq = int(state.get("shotSeq", known_shot_seq))
	_apply_state(state, true)

func _spawn_impact_fx_if_changed(new_heights: Array) -> void:
	var max_delta := 0.0
	var max_idx := -1
	for i in new_heights.size():
		var d: float = absf(float(new_heights[i]) - last_heights[i])
		if d > max_delta:
			max_delta = d
			max_idx = i
	if max_idx != -1 and max_delta > 1.0:
		effects.spawn_explosion(max_idx * Constants.TERRAIN_RES, new_heights[max_idx])

func _sync_obstacles(obstacles_data: Array) -> void:
	if obstacles_data.size() != rock_nodes.size():
		for r in rock_nodes:
			r.queue_free()
		rock_nodes.clear()

		var biome: Dictionary = Biomes.get_biome(current_biome_id)
		for data in obstacles_data:
			var r: Rock = RockScene.instantiate()
			obstacles_node.add_child(r)
			r.apply_palette(biome.rock, biome.rock_accent)
			r.position = Vector2(data.x, data.y)
			r.setup(data.radius, data.maxHealth)
			r.health = data.health
			rock_nodes.append(r)
	else:
		for i in obstacles_data.size():
			var data = obstacles_data[i]
			rock_nodes[i].health = data.health
			rock_nodes[i].queue_redraw()

func _sync_players(players_data: Array) -> void:
	var incoming_ids: Array = players_data.map(func(p): return p.id)
	if incoming_ids != known_player_ids:
		known_player_ids = incoming_ids
		var colors: Array = players_data.map(func(p): return Color(String(p.color)))
		var labels: Array = players_data.map(func(p): return p.label)
		var teams: Array = players_data.map(func(p): return p.team)
		hud.setup_players(incoming_ids, colors, labels, teams)

	for p in players_data:
		var node: Player
		if player_nodes.has(p.id):
			node = player_nodes[p.id]
		else:
			node = PlayerScene.instantiate()
			players_host.add_child(node)
			node.player_id = p.id
			node.terrain = terrain
			player_nodes[p.id] = node

		node.species = p.species
		node.body_color = Color(String(p.color))
		node.dir = int(p.dir)
		node.team = int(p.team)
		node.position = Vector2(p.x, p.y)
		node.weapon_id = selected_weapon_id if p.id == my_player_id else Weapons.DEFAULT_ID

		var was_alive: bool = last_health.get(p.id, 100.0) > 0.0
		node.health = p.health
		if was_alive and p.health <= 0.0:
			effects.spawn_ko_burst(node.position.x, node.anchor().y)
		last_health[p.id] = p.health

		hud.set_health(p.id, p.health)

func _label_for(state: Dictionary, player_id: String) -> String:
	for p in state.players:
		if p.id == player_id:
			return String(p.label)
	return player_id

func _wind_text(wind: float) -> String:
	var abs_wind := absf(wind)
	var strength := "calma"
	if abs_wind > 1.1:
		strength = "fuerte"
	elif abs_wind > 0.5:
		strength = "moderado"
	elif abs_wind > 0.15:
		strength = "suave"
	if strength == "calma":
		return "💨 Viento: calma"
	var arrow := "➡️" if wind > 0 else "⬅️"
	return "💨 Viento %s %s" % [strength, arrow]

func _show_podium(state: Dictionary) -> void:
	var labels := {}
	for p in state.players:
		labels[p.id] = p.label
	var ranking: Array = state.ranking if state.ranking != null else []
	hud.show_podium(ranking, labels)
	hud.show_restart(true)

func _my_turn() -> bool:
	if last_state.is_empty() or last_state.phase != "playing":
		return false
	var current_id: String = last_state.turnOrder[last_state.currentTurnIndex]
	return current_id == my_player_id

func _my_player() -> Player:
	return player_nodes.get(my_player_id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_pointer_down(get_viewport().get_mouse_position())
		else:
			_on_pointer_up()
	elif event is InputEventMouseMotion:
		_on_pointer_move(get_viewport().get_mouse_position())

func _on_pointer_down(pos: Vector2) -> void:
	if not _my_turn() or predicting_shot:
		return
	var p := _my_player()
	if p == null:
		return
	if pos.distance_to(p.anchor()) <= Constants.GRAB_RADIUS:
		drag_active = true
		drag_cur = pos
		p.is_aiming = true
		p.aim_point = pos
		aim_overlay.active = true
		aim_overlay.anchor = p.anchor()
		aim_overlay.target = pos
		aim_overlay.queue_redraw()

func _on_pointer_move(pos: Vector2) -> void:
	if not drag_active:
		return
	var p := _my_player()
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
	var p := _my_player()
	var anchor := p.anchor()
	var delta := drag_cur - anchor
	var pull_dist := delta.length()

	drag_active = false
	p.is_aiming = false
	aim_overlay.active = false
	aim_overlay.queue_redraw()

	if pull_dist < 12.0:
		return

	p.trigger_recoil()
	NetworkClient.fire(-delta.x, -delta.y, selected_weapon_id)
	hud.set_hint("Disparo enviado...")
