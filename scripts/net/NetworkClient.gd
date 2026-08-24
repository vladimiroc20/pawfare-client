extends Node

signal joined(state: Dictionary)
signal join_failed(error: String)
signal state_updated(state: Dictionary)
signal action_failed(error: String)

@export var base_url: String = "http://127.0.0.1:2567/api"

var room_id: String = ""
var player_id: String = ""
var token: String = ""
var last_state: Dictionary = {}

var _poll_timer: Timer
var _heartbeat_timer: Timer

func _ready() -> void:
	_poll_timer = Timer.new()
	_poll_timer.wait_time = 0.7
	_poll_timer.timeout.connect(_poll_state)
	add_child(_poll_timer)

	_heartbeat_timer = Timer.new()
	_heartbeat_timer.wait_time = 5.0
	_heartbeat_timer.timeout.connect(_send_heartbeat)
	add_child(_heartbeat_timer)

func quickmatch(player_count: int, team_mode: bool, biome_id: String) -> void:
	var body := {"playerCount": player_count, "teamMode": team_mode, "biomeId": biome_id}
	_request("/quickmatch", HTTPClient.METHOD_POST, body, func(ok: bool, data: Dictionary):
		if ok:
			room_id = data.roomId
			player_id = data.playerId
			token = data.token
			last_state = data.state
			_poll_timer.start()
			_heartbeat_timer.start()
			joined.emit(last_state)
		else:
			join_failed.emit(String(data.get("error", "No se pudo conectar")))
	)

func fire(dx: float, dy: float, weapon_id: String = "bazooka") -> void:
	if room_id == "":
		return
	var body := {"playerId": player_id, "token": token, "dx": dx, "dy": dy, "weaponId": weapon_id}
	_request("/rooms/%s/fire" % room_id, HTTPClient.METHOD_POST, body, func(ok: bool, data: Dictionary):
		if ok:
			last_state = data.state
			state_updated.emit(last_state)
		else:
			action_failed.emit(String(data.get("error", "No se pudo disparar")))
	)

func leave_match() -> void:
	if room_id == "":
		return
	var body := {"playerId": player_id, "token": token}
	_request("/rooms/%s/leave" % room_id, HTTPClient.METHOD_POST, body, func(_ok, _data): pass)
	_poll_timer.stop()
	_heartbeat_timer.stop()
	room_id = ""
	player_id = ""
	token = ""
	last_state = {}

func _poll_state() -> void:
	if room_id == "":
		return
	_request("/rooms/%s/state" % room_id, HTTPClient.METHOD_GET, null, func(ok: bool, data: Dictionary):
		if ok:
			last_state = data
			state_updated.emit(last_state)
	)

func _send_heartbeat() -> void:
	if room_id == "":
		return
	var body := {"playerId": player_id, "token": token}
	_request("/rooms/%s/heartbeat" % room_id, HTTPClient.METHOD_POST, body, func(_ok, _data): pass)

func _request(path: String, method: HTTPClient.Method, body, callback: Callable) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_result: int, code: int, _headers: PackedStringArray, body_bytes: PackedByteArray):
		http.queue_free()
		var text := body_bytes.get_string_from_utf8()
		var parsed = JSON.parse_string(text)
		var ok := code >= 200 and code < 300
		var data: Dictionary = parsed if parsed is Dictionary else {}
		callback.call(ok, data)
	)
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err: int
	if method == HTTPClient.METHOD_GET:
		err = http.request(base_url + path, headers, HTTPClient.METHOD_GET)
	else:
		err = http.request(base_url + path, headers, method, JSON.stringify(body))
	if err != OK:
		http.queue_free()
		callback.call(false, {"error": "No se pudo conectar al servidor"})
