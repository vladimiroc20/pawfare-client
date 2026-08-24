extends RefCounted
class_name Constants

const SCREEN_W := 800.0
const SCREEN_H := 450.0

const GRAVITY := 0.09
const EXPLOSION_RADIUS := 36.0
const DAMAGE_RANGE := EXPLOSION_RADIUS + 20.0
const DAMAGE := 26.0
const MAX_PULL := 95.0
const POWER_SCALE := 0.09
const GRAB_RADIUS := 42.0
const TERRAIN_RES := 4.0

const KNOCKBACK_FORCE := 7.5
const KNOCK_GRAVITY := 0.5

const OBSTACLE_COUNT := 3
const ROCK_HIT_DAMAGE := 30.0

const MIN_PLAYERS := 2
const MAX_PLAYERS := 4

const PLAYER_COLORS := [
	Color("3b82f6"),
	Color("ef4444"),
	Color("22c55e"),
	Color("eab308"),
]
const PLAYER_SPECIES := ["dog", "cat", "dog", "cat"]
const PLAYER_LABELS := ["Jugador 1 🔵", "Jugador 2 🔴", "Jugador 3 🟢", "Jugador 4 🟡"]

const ROCK_SIZES := [
	{"min": 12.0, "max": 18.0, "hp": 30.0},
	{"min": 19.0, "max": 27.0, "hp": 55.0},
	{"min": 28.0, "max": 38.0, "hp": 85.0},
]
