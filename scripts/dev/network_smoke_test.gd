extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var client1: Node = load("res://scripts/net/NetworkClient.gd").new()
	var client2: Node = load("res://scripts/net/NetworkClient.gd").new()
	root.add_child(client1)
	root.add_child(client2)

	var joined1 := [false]
	var state1 := [{}]
	client1.joined.connect(func(state): joined1[0] = true; state1[0] = state)
	client1.join_failed.connect(func(err): push_error("client1 join_failed: " + err))

	client1.quickmatch(2, false, "backyard")
	await _wait_until(func(): return joined1[0], 5.0)
	assert(joined1[0], "client1 debe unirse a una sala")
	assert(state1[0].phase == "waiting", "la sala debe esperar al segundo jugador")

	var joined2 := [false]
	var state2 := [{}]
	client2.joined.connect(func(state): joined2[0] = true; state2[0] = state)
	client2.join_failed.connect(func(err): push_error("client2 join_failed: " + err))

	client2.quickmatch(2, false, "backyard")
	await _wait_until(func(): return joined2[0], 5.0)
	assert(joined2[0], "client2 debe unirse a la misma sala")
	assert(client1.room_id == client2.room_id, "ambos clientes deben caer en la misma sala")

	var latest_state := [{}]
	client1.state_updated.connect(func(s): latest_state[0] = s)

	await _wait_until(func():
		return not latest_state[0].is_empty() and latest_state[0].get("phase") == "playing"
	, 5.0)
	assert(latest_state[0].phase == "playing", "la partida debe iniciar con 2/2 jugadores")

	var current_id: String = latest_state[0].turnOrder[latest_state[0].currentTurnIndex]
	var shooter: Object = client1 if current_id == client1.player_id else client2

	var heights_before: Array = latest_state[0].terrainHeights.duplicate()
	shooter.fire(50.0, -20.0)

	await _wait_until(func():
		if latest_state[0].is_empty():
			return false
		var h: Array = latest_state[0].terrainHeights
		for i in h.size():
			if absf(float(h[i]) - float(heights_before[i])) > 0.001:
				return true
		return false
	, 5.0)

	print("network smoke test OK — quickmatch, misma sala, inicio de partida y disparo por red funcionan")
	quit(0)

func _wait_until(predicate: Callable, timeout_seconds: float) -> void:
	var elapsed := 0.0
	var step := 0.05
	while not predicate.call() and elapsed < timeout_seconds:
		await create_timer(step).timeout
		elapsed += step
	if not predicate.call():
		push_error("timeout esperando condición")
		quit(1)
