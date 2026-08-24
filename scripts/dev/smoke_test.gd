extends SceneTree

func _initialize() -> void:
	_run_case(2)
	_run_case(4)
	for biome in Biomes.LIST:
		_run_biome_case(biome.id)
	print("smoke test OK — jugadores (2/4), rotación de turno y todos los biomas cargan sin errores")
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

func _spawn_main(n: int, biome_id: String) -> Node:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	main.player_count = n
	main.biome_id = biome_id
	root.add_child(main)
	main.propagate_call("_ready")
	return main
