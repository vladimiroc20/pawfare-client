extends SceneTree

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	main.propagate_call("_ready")

	assert(main.player1.health == 100.0)
	assert(main.player2.health == 100.0)
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
	assert(main.player1.health < 100.0)
	assert(main.current_player_id == "p2")

	print("smoke test OK — disparo, cráter, daño y cambio de turno funcionan (p1 health: %.1f)" % main.player1.health)
	quit()
