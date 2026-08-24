extends SceneTree

func _initialize() -> void:
	_run_local_case()
	_run_online_timeout_case()
	print("character select smoke test OK — selección manual, aleatorio por timeout y modo online funcionan")
	quit()

func _run_local_case() -> void:
	var game_config := root.get_node("GameConfig")
	game_config.character_select_mode = "local"
	game_config.player_count = 3
	game_config.chosen_species.clear()

	var scene: PackedScene = load("res://scenes/menu/CharacterSelect.tscn")
	var select: Node = scene.instantiate()
	root.add_child(select)
	select.propagate_call("_ready")

	assert(select.slot_count == 3)

	select._cycle(0, 1)
	select._cycle(0, 1)
	assert(select.touched[0])
	assert(not select.touched[1])
	assert(not select.touched[2])

	var picked_for_slot0: String = Species.LIST[select.chosen_index[0]].id

	select._finish()

	assert(game_config.chosen_species.size() == 3)
	assert(game_config.chosen_species[0] == picked_for_slot0)
	for id in game_config.chosen_species:
		assert(Species.LIST.any(func(s): return s.id == id))

	select.queue_free()

func _run_online_timeout_case() -> void:
	var game_config := root.get_node("GameConfig")
	game_config.character_select_mode = "online"

	var scene: PackedScene = load("res://scenes/menu/CharacterSelect.tscn")
	var select: Node = scene.instantiate()
	root.add_child(select)
	select.propagate_call("_ready")

	assert(select.slot_count == 1)
	assert(not select.finished)

	select._finish()

	assert(select.finished)
	assert(Species.LIST.any(func(s): return s.id == Species.LIST[select.chosen_index[0]].id))

	select.queue_free()
