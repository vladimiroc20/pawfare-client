extends RefCounted
class_name DrawUtils

static func ellipse_points(center: Vector2, rx: float, ry: float, rotation: float = 0.0, segments: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * i / segments
		var p := Vector2(cos(a) * rx, sin(a) * ry).rotated(rotation)
		pts.append(center + p)
	return pts

static func quad_bezier_points(p0: Vector2, control: Vector2, p1: Vector2, segments: int = 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments + 1:
		var t := float(i) / segments
		var a := p0.lerp(control, t)
		var b := control.lerp(p1, t)
		pts.append(a.lerp(b, t))
	return pts

static func lerp_stops(stops: Array, t: float) -> Color:
	for i in range(stops.size() - 1):
		var a: Array = stops[i]
		var b: Array = stops[i + 1]
		if t >= a[0] and t <= b[0]:
			var local_t: float = (t - a[0]) / (b[0] - a[0]) if b[0] > a[0] else 0.0
			return a[1].lerp(b[1], local_t)
	return stops[-1][1]
