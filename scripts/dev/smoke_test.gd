extends SceneTree

func _initialize() -> void:
	seed(1)
	_run_case(2)
	_run_case(4)
	for biome in Biomes.LIST:
		_run_biome_case(biome.id)
	_run_elimination_case()
	_run_team_mode_case()
	_run_weapons_case()
	print("smoke test OK — jugadores (2/4), biomas, eliminación/podio, modo equipos y armas funcionan")
	quit()

func _run_case(n: int) -> void:
	var main := _spawn_main(n, "backyard")

	assert(main.players.size() == n)
	for p in main.players:
		assert(p.health == 100.0)
	assert(main.obstacles.size() == Constants.OBSTACLE_COUNT)

	var p = main.current_player()
	var anchor: Vector2 = p.anchor()
	main._on_pointer_down(anchor)
	main._on_pointer_move(anchor + Vector2(50, -20))
	main._on_pointer_up()
	assert(main.projectile != null)

	var frames := 0
	while main.projectile != null and frames < 400:
		main._physics_process(1.0 / 60.0)
		frames += 1

	assert(frames < 400)
	assert(main.players[0].health < 100.0)
	assert(main.current_turn_index != 0)

	main.queue_free()

func _run_biome_case(biome_id: String) -> void:
	var main := _spawn_main(2, biome_id)
	var biome: Dictionary = Biomes.get_biome(biome_id)
	var expected_count: int = clampi(Constants.OBSTACLE_COUNT + int(biome.get("obstacle_delta", 0)), 1, 6)
	assert(main.obstacles.size() == expected_count)
	assert(main.background.is_night == biome.is_night)
	main.queue_free()

func _run_elimination_case() -> void:
	var main := _spawn_main(2, "backyard")
	var loser: Player = main.players[1]

	loser.take_damage(1000.0)
	assert(loser.is_down())
	assert(main.elimination_order.has("p2"))

	main._end_turn_check()
	assert(main.game_over)

	var ranking: Array = main._build_ranking()
	assert(ranking.size() == 2)
	assert(ranking[0].ids == ["p1"])
	assert(ranking[1].ids == ["p2"])

	main.queue_free()

func _run_team_mode_case() -> void:
	var main := _spawn_main(4, "backyard", true)

	assert(main.players[0].team == 0)
	assert(main.players[1].team == 1)
	assert(main.players[2].team == 0)
	assert(main.players[3].team == 1)

	main.players[0].take_damage(1000.0)
	main.players[2].take_damage(1000.0)
	main._end_turn_check()
	assert(main.game_over)

	var ranking: Array = main._build_ranking()
	assert(ranking.size() == 2)
	assert(ranking[0].ids.has("p2") and ranking[0].ids.has("p4"))
	assert(ranking[1].ids.has("p1") and ranking[1].ids.has("p3"))

	main.queue_free()

func _run_weapons_case() -> void:
	var bazooka_runs := _fire_and_count_runs("bazooka", Vector2(50, -20))
	assert(bazooka_runs == 1)

	var cluster_runs := _fire_and_count_runs("cluster", Vector2(50, -20))
	assert(cluster_runs > 1)

	var bouncer_runs := _fire_and_count_runs("bouncer", Vector2(-20, -60))
	assert(bouncer_runs >= 1)

func _fire_and_count_runs(weapon_id: String, pull: Vector2) -> int:
	var main := _spawn_main(2, "backyard")
	main.active_weapon = Weapons.get_weapon(weapon_id)

	var p = main.current_player()
	var anchor: Vector2 = p.anchor()
	var heights_before: PackedFloat32Array = main.terrain.heights.duplicate()

	main._on_pointer_down(anchor)
	main._on_pointer_move(anchor + pull)
	main._on_pointer_up()
	assert(main.projectile != null)

	var frames := 0
	while main.projectile != null and frames < 400:
		main._physics_process(1.0 / 60.0)
		frames += 1
	assert(frames < 400)

	var heights_after: PackedFloat32Array = main.terrain.heights
	var runs := 0
	var was_affected := false
	for i in heights_before.size():
		var affected: bool = absf(heights_before[i] - heights_after[i]) > 0.5
		if affected and not was_affected:
			runs += 1
		was_affected = affected

	main.queue_free()
	return runs

func _spawn_main(n: int, biome_id: String, team_mode: bool = false) -> Node:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	main.player_count = n
	main.biome_id = biome_id
	main.is_team_mode = team_mode
	root.add_child(main)
	main.propagate_call("_ready")
	return main
