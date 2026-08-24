extends Node2D
class_name Terrain

const RES := 4.0

var heights: PackedFloat32Array = PackedFloat32Array()
var samples: int = 0

var gradient_stops: Array = Biomes.LIST[0].terrain
var grass_color: Color = Biomes.LIST[0].grass

func _ready() -> void:
	samples = int(Constants.SCREEN_W / RES) + 1
	generate_terrain()

func set_biome(biome: Dictionary) -> void:
	gradient_stops = biome.terrain
	grass_color = biome.grass
	queue_redraw()

func set_heights(new_heights: Array) -> void:
	heights = PackedFloat32Array(new_heights)
	samples = heights.size()
	queue_redraw()

func generate_terrain() -> void:
	heights.resize(samples)
	var baseline := Constants.SCREEN_H * 0.62
	var amp1 := 40.0
	var amp2 := 18.0
	var seed_a := randf() * 1000.0
	var seed_b := randf() * 1000.0
	for i in samples:
		var x := i * RES
		heights[i] = baseline \
			- amp1 * sin((x + seed_a) * 0.006) \
			- amp2 * sin((x + seed_b) * 0.017)
	queue_redraw()

func height_at(x: float) -> float:
	x = clampf(x, 0.0, Constants.SCREEN_W - 0.001)
	var idx := x / RES
	var i0 := int(floor(idx))
	var i1 := mini(samples - 1, i0 + 1)
	var t := idx - i0
	return heights[i0] * (1.0 - t) + heights[i1] * t

func is_below_ground(x: float, y: float) -> bool:
	return y >= height_at(x)

func carve_crater(cx: float, cy: float, radius: float) -> void:
	for i in samples:
		var sx := i * RES
		var dx := sx - cx
		if absf(dx) > radius:
			continue
		var half_chord := sqrt(maxf(0.0, radius * radius - dx * dx))
		var candidate := cy + half_chord * 0.9
		if candidate > heights[i]:
			heights[i] = minf(Constants.SCREEN_H, candidate)
	queue_redraw()

func _draw() -> void:
	_draw_fill()
	_draw_grass_tufts()

func _draw_fill() -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var top := Constants.SCREEN_H * 0.55
	var span := Constants.SCREEN_H - top

	points.append(Vector2(0, Constants.SCREEN_H))
	colors.append(gradient_stops[-1][1])
	for i in samples:
		var x := i * RES
		var y: float = heights[i]
		var t: float = clampf((y - top) / span, 0.0, 1.0)
		points.append(Vector2(x, y))
		colors.append(DrawUtils.lerp_stops(gradient_stops, t))
	points.append(Vector2(Constants.SCREEN_W, Constants.SCREEN_H))
	colors.append(gradient_stops[-1][1])

	draw_polygon(points, colors)

func _draw_grass_tufts() -> void:
	var col := grass_color
	var i := 0
	while i < samples:
		var x := i * RES
		var y: float = heights[i]
		draw_line(Vector2(x - 3, y + 1), Vector2(x - 4, y - 6), col, 2.0)
		draw_line(Vector2(x, y + 1), Vector2(x + 1, y - 8), col, 2.0)
		draw_line(Vector2(x + 3, y + 1), Vector2(x + 4, y - 5), col, 2.0)
		i += 6
