extends Control

func _ready():
	# Find the RiveControl and start its state machine
	var rive = $RiveControl
	if rive:
		print("RiveControl found, SM: ", rive.state_machine_name)

func _input(event):
	# Forward input to RiveControl for interactive .riv files
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var rive = $RiveControl
		if rive:
			rive._input(event)
