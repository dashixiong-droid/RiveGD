extends Control

func _ready():
	# Load the .riv file bytes manually
	var fa = FileAccess.open("res://hosted_font_file.riv", FileAccess.READ)
	if fa == null:
		print("FontOBBTest: FAILED to open hosted_font_file.riv")
		return
	var data = fa.get_buffer(fa.get_length())
	fa.close()
	print("FontOBBTest: Read %d bytes from hosted_font_file.riv" % data.size())
	
	# Create RiveFile resource
	var rf = RiveFile.new()
	rf.set_source_path("res://hosted_font_file.riv")
	rf.set_data(data)
	
	# Create RiveControl
	var rc = RiveControl.new()
	rc.set_rive_file(rf)
	rc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(rc)
	print("FontOBBTest: RiveControl added with hosted_font_file.riv")
