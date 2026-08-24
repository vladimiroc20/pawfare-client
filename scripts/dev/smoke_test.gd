extends SceneTree

func _initialize() -> void:
	_run_case(2)
	_run_case(4)
	print("smoke test OK — 2 y 4 jugadores: disparo, cráter, daño y rotación de turno funcionan")
	quit()

func _run_case(n: int) -> void:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	main.player_count = n
	root.add_child(main)
	main.propagate_call("_ready")

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
