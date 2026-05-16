extends Control

## Test script for Rive Events signal
## Connects to rive_event signal and logs all events to console

var rive_ctrl: RiveControl
var elapsed: float = 0.0

func _ready():
	rive_ctrl = RiveControl.new()
	rive_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(rive_ctrl)
	
	# Connect event signal
	rive_ctrl.rive_event.connect(_on_rive_event)
	
	# Load the test file
	var file = RiveFile.new()
	if file.load_file("res://events_on_states.riv"):
		rive_ctrl.rive_file = file
		print("[EventTest] Loaded events_on_states.riv, waiting for events...")
	else:
		push_error("[EventTest] Failed to load events_on_states.riv")

func _process(delta):
	elapsed += delta
	if elapsed > 10.0:
		print("[EventTest] 10s elapsed, no more events expected")
		set_process(false)

func _on_rive_event(event_name: String, properties: Dictionary, delay: float) -> void:
	print("[RiveEvent] name=%s properties=%s delay=%.4f" % [event_name, properties, delay])
