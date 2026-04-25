extends Node2D

# Minimal demo: download Ghostscript_Tiger.svg from the web, parse with
# RiveSVG, and render through a RiveCanvas2D + RiveRaw.

const TIGER_URL := "https://upload.wikimedia.org/wikipedia/commons/f/fd/Ghostscript_Tiger.svg"

@onready var raw: RiveRaw = $RiveCanvas2D/RiveRaw

var _svg: RiveSVG
var _http: HTTPRequest


func _ready() -> void:
	raw.draw_rive.connect(_on_draw_rive)
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_http.request(TIGER_URL)


func _on_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		push_error("SVG download failed (result=%d code=%d)" % [result, code])
		return
	_svg = RiveSVG.new()
	var xml := body.get_string_from_utf8()
	_svg.parse(xml)
	queue_redraw()


func _on_draw_rive(renderer: RiveRendererWrapper) -> void:
	if _svg == null:
		return
	renderer.save()
	renderer.translate(64, 64)
	_svg.draw(renderer)
	renderer.restore()
