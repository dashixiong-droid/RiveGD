extends Node

# Demo: custom Rive drawing using the new RivePath / RivePaint / RiveGradient /
# RiveRendererWrapper.clip_path APIs.
#
# Hook this script's _on_draw_rive(renderer) up to a RiveRaw node's "draw_rive"
# signal. The RiveRaw should be parented under a RiveCanvas2D.

@export var canvas_size: Vector2 = Vector2(1920, 1080)
@export var image_texture: Texture2D

var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta

# --- Cached resources (recreated lazily; the renderer factory must be ready) ---
var _bg_path: RivePath
var _bg_paint: RivePaint
var _bg_gradient: RiveGradient

var _blob_path: RivePath
var _blob_fill: RivePaint
var _blob_stroke: RivePaint

var _ring_path: RivePath
var _ring_paint: RivePaint

var _clip_path: RivePath
var _burst_path: RivePath
var _clipped_fill: RivePaint
var _clipped_gradient: RiveGradient

# SVG / composite / image showcase
var _svg_path: RivePath
var _svg_fill: RivePaint
var _svg_stroke: RivePaint
var _composite_path: RivePath
var _composite_fill: RivePaint
var _rive_image: RiveImage

# add_poly + bounds showcase
var _poly_path: RivePath
var _poly_fill: RivePaint
var _poly_stroke: RivePaint
var _bbox_paint: RivePaint
var _bbox_path: RivePath

# draw_image_mesh showcase
const MESH_DIVS := 12
const MESH_SIZE := 280.0
var _mesh_verts: PackedVector2Array
var _mesh_uvs: PackedVector2Array
var _mesh_indices: PackedInt32Array


func _ensure_resources() -> void:
	if _bg_paint == null:
		_bg_gradient = RiveGradient.new()
		_bg_gradient.set_linear(Vector2(0, 0), Vector2(0, canvas_size.y))
		_bg_gradient.set_stops(
			PackedColorArray([Color(0.05, 0.07, 0.12, 1), Color(0.18, 0.10, 0.32, 1)]),
			PackedFloat32Array([0.0, 1.0]),
		)
		_bg_paint = RivePaint.new()
		_bg_paint.set_style(1) # Fill
		_bg_paint.set_gradient(_bg_gradient)

		_bg_path = RivePath.new()
		_bg_path.add_rect(0, 0, canvas_size.x, canvas_size.y)

	if _blob_fill == null:
		_blob_fill = RivePaint.new()
		_blob_fill.set_style(1)
		_blob_fill.set_color(Color(1.0, 0.45, 0.55, 0.9))
		_blob_fill.set_feather(8.0)

		_blob_stroke = RivePaint.new()
		_blob_stroke.set_style(0) # Stroke
		_blob_stroke.set_color(Color(1, 1, 1, 0.85))
		_blob_stroke.set_thickness(4.0)
		_blob_stroke.set_join(2) # Round
		_blob_stroke.set_cap(1)  # Round

		_blob_path = RivePath.new()

	if _ring_paint == null:
		_ring_paint = RivePaint.new()
		_ring_paint.set_style(0)
		_ring_paint.set_color(Color(0.4, 0.9, 1.0, 0.95))
		_ring_paint.set_thickness(6.0)
		_ring_paint.set_cap(1)

		_ring_path = RivePath.new()

	if _clipped_fill == null:
		_clipped_gradient = RiveGradient.new()
		_clipped_gradient.set_radial(Vector2(0, 0), 260.0)
		_clipped_gradient.set_stops(
			PackedColorArray([
				Color(1.0, 0.95, 0.4, 1),
				Color(1.0, 0.5, 0.2, 1),
				Color(0.6, 0.0, 0.4, 0),
			]),
			PackedFloat32Array([0.0, 0.5, 1.0]),
		)
		_clipped_fill = RivePaint.new()
		_clipped_fill.set_style(1)
		_clipped_fill.set_gradient(_clipped_gradient)

		_clip_path = RivePath.new()
		_burst_path = RivePath.new()
		_burst_path.add_rect(-400, -400, 800, 800)

	if _svg_path == null:
		# Heart shape using SVG path data — exercises M, C, A and Z commands.
		_svg_path = RivePath.new()
		_svg_path.parse_svg(
			"M 0 -40 "
			+ "C 30 -90 100 -60 100 -10 "
			+ "A 60 60 0 0 1 0 90 "
			+ "A 60 60 0 0 1 -100 -10 "
			+ "C -100 -60 -30 -90 0 -40 Z"
		)
		_svg_fill = RivePaint.new()
		_svg_fill.set_style(1)
		_svg_fill.set_color(Color(1, 0.25, 0.4, 1))
		_svg_stroke = RivePaint.new()
		_svg_stroke.set_style(0)
		_svg_stroke.set_color(Color(1, 1, 1, 0.85))
		_svg_stroke.set_thickness(3.0)
		_svg_stroke.set_join(2)

	if _composite_path == null:
		# Build a composite shape: rounded badge made by add_path of primitives.
		var rect_part := RivePath.new()
		rect_part.add_rect(-90, -50, 180, 100)
		var left_cap := RivePath.new()
		left_cap.add_circle(-90, 0, 50)
		var right_cap := RivePath.new()
		right_cap.add_circle(90, 0, 50)
		_composite_path = RivePath.new()
		_composite_path.add_path(rect_part)
		_composite_path.add_path(left_cap)
		_composite_path.add_path(right_cap)
		_composite_fill = RivePaint.new()
		_composite_fill.set_style(1)
		_composite_fill.set_color(Color(0.2, 0.95, 0.6, 1))
		_composite_fill.set_feather(4.0)

	if _rive_image == null and image_texture:
		_rive_image = RiveImage.new()
		if not _rive_image.load_from_texture(image_texture):
			_rive_image = null

	if _poly_path == null:
		_poly_path = RivePath.new()
		_poly_fill = RivePaint.new()
		_poly_fill.set_style(1)
		_poly_fill.set_color(Color(0.55, 0.7, 1.0, 0.55))
		_poly_stroke = RivePaint.new()
		_poly_stroke.set_style(0)
		_poly_stroke.set_color(Color(0.7, 0.85, 1.0, 1.0))
		_poly_stroke.set_thickness(3.0)
		_poly_stroke.set_join(2)
		_bbox_paint = RivePaint.new()
		_bbox_paint.set_style(0)
		_bbox_paint.set_color(Color(1.0, 1.0, 0.3, 0.95))
		_bbox_paint.set_thickness(4.0)
		_bbox_path = RivePath.new()


func _on_draw_rive(renderer: RiveRendererWrapper) -> void:
	_ensure_resources()

	# 1) Gradient background fill of the whole canvas.
	renderer.draw_path(_bg_path, _bg_paint)

	# 2) Animated blob: morphing closed path with cubic + quad segments.
	_rebuild_blob_path()
	renderer.save()
	renderer.translate(canvas_size.x * 0.5, canvas_size.y * 0.5)
	renderer.draw_path(_blob_path, _blob_fill)
	renderer.draw_path(_blob_path, _blob_stroke)
	renderer.restore()

	# 3) Rotating dashed-style ring (stroked oval segments).
	_rebuild_ring_path()
	renderer.save()
	renderer.translate(canvas_size.x * 0.5, canvas_size.y * 0.5)
	renderer.rotate(_time * 0.6)
	renderer.draw_path(_ring_path, _ring_paint)
	renderer.restore()

	# 4) Clipping demo: animated circular clip reveals a radial-gradient burst.
	_rebuild_clip_path()
	renderer.save()
	renderer.translate(canvas_size.x * 0.5, canvas_size.y * 0.5)
	renderer.clip_path(_clip_path)
	# Draw something larger than the clip; only the clipped region is visible.
	renderer.draw_path(_burst_path, _clipped_fill)
	renderer.restore()

	# 5) SVG path heart (top-left corner), pulsing scale.
	var s := 1.0 + 0.1 * sin(_time * 3.0)
	renderer.save()
	renderer.translate(220, 220)
	renderer.scale(s, s)
	renderer.draw_path(_svg_path, _svg_fill)
	renderer.draw_path(_svg_path, _svg_stroke)
	renderer.restore()

	# 6) Composite path (top-right): rectangle + two caps merged via add_path.
	renderer.save()
	renderer.translate(canvas_size.x - 220, 220)
	renderer.rotate(sin(_time) * 0.2)
	renderer.draw_path(_composite_path, _composite_fill)
	renderer.restore()

	# 7) Image (bottom-right) — only drawn if a texture was assigned.
	if _rive_image and _rive_image.is_loaded():
		var iw := float(_rive_image.get_width())
		var ih := float(_rive_image.get_height())
		var target := 220.0
		var sc : float = target / max(iw, ih)
		renderer.save()
		renderer.translate(canvas_size.x - 220, canvas_size.y - 220)
		renderer.rotate(_time * 0.4)
		renderer.scale(sc, sc)
		renderer.translate(-iw * 0.5, -ih * 0.5)
		renderer.draw_image(_rive_image, 1.0, 3) # 3 = SrcOver
		renderer.restore()

	# 9) draw_image_mesh: a wavy textured grid at top-center.
	if _rive_image and _rive_image.is_loaded():
		_rebuild_mesh()
		renderer.save()
		renderer.translate(canvas_size.x * 0.5, 220)
		renderer.draw_image_mesh(_rive_image, _mesh_verts, _mesh_uvs, _mesh_indices, 1.0, 3)
		renderer.restore()

	# 8) add_poly + get_bounds: animated polygon with its bounding box overlay.
	_rebuild_poly_path()
	renderer.save()
	renderer.translate(canvas_size.x * 0.5, canvas_size.y - 220)
	# IMPORTANT: read bounds BEFORE drawing — drawing consumes raw_path internally.
	var bb := _poly_path.get_bounds()
	renderer.draw_path(_poly_path, _poly_fill)
	renderer.draw_path(_poly_path, _poly_stroke)
	if bb.size.x > 0 and bb.size.y > 0:
		_bbox_path.reset()
		_bbox_path.add_rect(bb.position.x, bb.position.y, bb.size.x, bb.size.y)
		renderer.draw_path(_bbox_path, _bbox_paint)
	renderer.restore()


func _rebuild_blob_path() -> void:
	_blob_path.reset()
	var r0 := 140.0
	var r1 := 180.0
	var n := 6
	var t := _time * 1.4
	# Build a wobbly closed shape with cubic_to between sample points.
	var points := PackedVector2Array()
	for i in range(n):
		var a := (TAU * i) / n
		var r := lerpf(r0, r1, 0.5 + 0.5 * sin(t + a * 2.0))
		points.append(Vector2(cos(a), sin(a)) * r)
	_blob_path.move_to(points[0].x, points[0].y)
	for i in range(n):
		var p0: Vector2 = points[i]
		var p1: Vector2 = points[(i + 1) % n]
		# Tangents perpendicular-ish for smooth curves.
		var t0 := Vector2(-p0.y, p0.x).normalized() * 60.0
		var t1 := Vector2(p1.y, -p1.x).normalized() * 60.0
		_blob_path.cubic_to(p0.x + t0.x, p0.y + t0.y, p1.x + t1.x, p1.y + t1.y, p1.x, p1.y)
	_blob_path.close()


func _rebuild_ring_path() -> void:
	_ring_path.reset()
	var radius := 280.0
	var dashes := 24
	var arc := TAU / float(dashes)
	# Approximate each dash as a quadratic curve segment along the circle.
	for i in range(dashes):
		if i % 2 == 1:
			continue
		var a0 := i * arc
		var a1 := a0 + arc * 0.6
		var am := (a0 + a1) * 0.5
		var p0 := Vector2(cos(a0), sin(a0)) * radius
		var p1 := Vector2(cos(a1), sin(a1)) * radius
		# Pull the control point outward to bow the segment along the circle.
		var ctrl_r := radius / cos((a1 - a0) * 0.5)
		var pc := Vector2(cos(am), sin(am)) * ctrl_r
		_ring_path.move_to(p0.x, p0.y)
		_ring_path.quad_to(pc.x, pc.y, p1.x, p1.y)


func _rebuild_clip_path() -> void:
	_clip_path.reset()
	var pulse := 200.0 + 60.0 * sin(_time * 2.0)
	# Pulsing star: alternate inner/outer radius via add_circle + cut-outs.
	# Simpler: use add_oval to clip to an animated ellipse.
	var w := pulse * 1.6
	var h := pulse
	_clip_path.add_oval(-w, -h, w * 2.0, h * 2.0)


func _rebuild_poly_path() -> void:
	_poly_path.reset()
	var n := 9
	var r0 := 70.0
	var r1 := 140.0
	var t := _time * 0.8
	var pts := PackedVector2Array()
	for i in range(n * 2):
		var a : float = (TAU * i) / float(n * 2) - PI * 0.5
		var r : float = r0 if (i % 2) == 0 else r1
		r += 12.0 * sin(t * 2.0 + a * 3.0)
		pts.push_back(Vector2(cos(a) * r, sin(a) * r))
	_poly_path.add_poly(pts, true)


func _ensure_mesh_topology() -> void:
	if _mesh_indices.size() > 0:
		return
	var n := MESH_DIVS + 1
	_mesh_uvs = PackedVector2Array()
	_mesh_uvs.resize(n * n)
	_mesh_verts = PackedVector2Array()
	_mesh_verts.resize(n * n)
	for j in range(n):
		for i in range(n):
			_mesh_uvs[j * n + i] = Vector2(float(i) / float(MESH_DIVS), float(j) / float(MESH_DIVS))
	_mesh_indices = PackedInt32Array()
	for j in range(MESH_DIVS):
		for i in range(MESH_DIVS):
			var a := j * n + i
			var b := a + 1
			var c := a + n
			var d := c + 1
			_mesh_indices.push_back(a); _mesh_indices.push_back(b); _mesh_indices.push_back(c)
			_mesh_indices.push_back(b); _mesh_indices.push_back(d); _mesh_indices.push_back(c)


func _rebuild_mesh() -> void:
	_ensure_mesh_topology()
	var n := MESH_DIVS + 1
	var half := MESH_SIZE * 0.5
	var t := _time
	for j in range(n):
		for i in range(n):
			var u : float = float(i) / float(MESH_DIVS)
			var v : float = float(j) / float(MESH_DIVS)
			var x : float = lerpf(-half, half, u)
			var y : float = lerpf(-half, half, v)
			# Wave displacement.
			x += 18.0 * sin(t * 2.0 + v * TAU)
			y += 18.0 * cos(t * 2.0 + u * TAU)
			_mesh_verts[j * n + i] = Vector2(x, y)