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

## Godot no rellena polígonos arbitrarios con degradado radial sin un shader —
## esto lo simula apilando elipses cada vez más chicas y opacas hacia el
## centro, el truco clásico de dibujo 2D por capas para lograr una sombra o
## brillo con caída suave en vez de una forma plana de borde duro.
static func draw_soft_blob(node: CanvasItem, center: Vector2, rx: float, ry: float, color: Color, layers: int = 4) -> void:
	for i in layers:
		var t := float(i) / float(layers)
		var scale := 1.0 - t * 0.55
		var alpha := color.a * (0.22 + 0.18 * i)
		node.draw_colored_polygon(ellipse_points(center, rx * scale, ry * scale), Color(color.r, color.g, color.b, alpha))

## Un "tubo" con puntas redondeadas (rectángulo + un círculo en cada extremo) —
## Godot no tiene rect de esquinas redondeadas nativo. Es la pieza base para el
## look de arma-juguete chiquita/robusta en vez de tubos de esquina dura.
## `outline` opcional dibuja un contorno grueso alrededor (look "sticker" tipo
## Wild Ones: el volumen lo da el contorno, no un degradado).
static func draw_capsule(node: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color, outline: Color = Color(0, 0, 0, 0), outline_width: float = 2.2) -> void:
	var dir := (to - from).normalized()
	var normal := Vector2(-dir.y, dir.x) * (width * 0.5)
	node.draw_colored_polygon(PackedVector2Array([from + normal, to + normal, to - normal, from - normal]), color)
	node.draw_circle(from, width * 0.5, color)
	node.draw_circle(to, width * 0.5, color)
	if outline.a > 0.0:
		node.draw_line(from + normal, to + normal, outline, outline_width)
		node.draw_line(from - normal, to - normal, outline, outline_width)
		var angle := dir.angle()
		node.draw_arc(to, width * 0.5, angle - PI * 0.5, angle + PI * 0.5, 10, outline, outline_width)
		node.draw_arc(from, width * 0.5, angle + PI * 0.5, angle + PI * 1.5, 10, outline, outline_width)

static func lerp_stops(stops: Array, t: float) -> Color:
	for i in range(stops.size() - 1):
		var a: Array = stops[i]
		var b: Array = stops[i + 1]
		if t >= a[0] and t <= b[0]:
			var local_t: float = (t - a[0]) / (b[0] - a[0]) if b[0] > a[0] else 0.0
			return a[1].lerp(b[1], local_t)
	return stops[-1][1]
