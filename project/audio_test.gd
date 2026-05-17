extends Control

## Audio test for RiveGD
## Uses sound.riv (has Listeners, click to trigger audio)
## Receives rive_audio_event signal with raw audio bytes, plays via Godot AudioStreamPlayer

var rive_ctrl: RiveControl
var log_file: FileAccess
var elapsed: float = 0.0
var clicked: bool = false
var audio_player: AudioStreamPlayer

func _ready():
	log_file = FileAccess.open("user://audio_test_log.txt", FileAccess.WRITE)
	write_log("=== RiveGD Audio Test (Godot Playback) ===")
	
	# Create an AudioStreamPlayer for playback
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	rive_ctrl = RiveControl.new()
	rive_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(rive_ctrl)
	
	rive_ctrl.rive_event.connect(_on_rive_event)
	rive_ctrl.rive_audio_event.connect(_on_rive_audio_event)
	
	# Load sound.riv (has Listener, responds to click)
	var file = FileAccess.open("res://sound.riv", FileAccess.READ)
	if file:
		var data = file.get_buffer(file.get_length())
		write_log("Read %d bytes from sound.riv" % data.size())
		
		var rive_file = RiveFile.new()
		rive_file.set_source_path("res://sound.riv")
		rive_file.set_data(data)
		rive_ctrl.set_rive_file(rive_file)
		write_log("Rive file set, state_machines: %s" % str(rive_ctrl.get_state_machine_list()))
		
		# Play default state machine
		var sms = rive_ctrl.get_state_machine_list()
		if sms.size() > 0:
			rive_ctrl.play_state_machine(sms[0])
			write_log("Playing state machine: %s" % sms[0])
	else:
		write_log("ERROR: Could not open sound.riv")

func _process(delta):
	elapsed += delta
	
	# Auto-click after 2 seconds to trigger audio
	if !clicked && elapsed > 2.0:
		clicked = true
		write_log("Simulating click at center (200, 200)")
		rive_ctrl.simulate_click(Vector2(200, 200))
		write_log("Click sent")
	
	if elapsed > 15.0:
		write_log("Test complete")
		log_file.close()
		get_tree().quit()

func _on_rive_event(name: String, properties: Dictionary, delay: float):
	write_log("EVENT: name=%s props=%s delay=%.3f" % [name, str(properties), delay])

func _on_rive_audio_event(name: String, audio_data: PackedByteArray, format: String, volume: float):
	write_log("AUDIO EVENT: name=%s format=%s volume=%.2f data_size=%d" % [name, format, volume, audio_data.size()])
	
	var stream: AudioStream = null
	
	if format == "wav":
		stream = _create_wav_stream(audio_data)
	elif format == "mp3":
		stream = _create_mp3_stream(audio_data)
	elif format == "flac":
		# FLAC not natively supported by Godot AudioStream
		# Could use AudioStreamOggVorbis if we transcode, but skip for now
		write_log("WARNING: FLAC format not directly supported by Godot, skipping")
	elif format == "opus":
		# Opus not natively supported either
		write_log("WARNING: Opus format not directly supported by Godot, skipping")
	
	if stream:
		audio_player.stream = stream
		audio_player.volume_db = linear_to_db(volume) if volume > 0.0 else 0.0
		audio_player.play()
		write_log("Playing audio: stream=%s volume_db=%.1f" % [stream.get_class(), audio_player.volume_db])
	else:
		write_log("WARNING: Could not create audio stream for format: %s" % format)

func _create_wav_stream(raw_data: PackedByteArray) -> AudioStreamWAV:
	"""Parse WAV header and create AudioStreamWAV from raw PCM data."""
	var stream = AudioStreamWAV.new()
	
	if raw_data.size() < 44:
		write_log("ERROR: WAV data too small (%d bytes)" % raw_data.size())
		return null
	
	# Parse WAV header
	# Bytes 0-3: "RIFF"
	var riff = raw_data.slice(0, 4).get_string_from_ascii()
	if riff != "RIFF":
		write_log("ERROR: Not a valid WAV file (RIFF header missing)")
		return null
	
	# Bytes 8-11: "WAVE"
	var wave = raw_data.slice(8, 12).get_string_from_ascii()
	if wave != "WAVE":
		write_log("ERROR: Not a valid WAV file (WAVE header missing)")
		return null
	
	# Find "fmt " chunk
	var offset = 12
	var fmt_found = false
	var audio_format = 0  # 1=PCM, 3=IEEE float
	var num_channels = 0
	var sample_rate = 0
	var bits_per_sample = 0
	var data_offset = 0
	var data_size = 0
	
	while offset < raw_data.size() - 8:
		var chunk_id = raw_data.slice(offset, offset + 4).get_string_from_ascii()
		var chunk_size = raw_data[offset + 4] | (raw_data[offset + 5] << 8) | (raw_data[offset + 6] << 16) | (raw_data[offset + 7] << 24)
		
		if chunk_id == "fmt ":
			fmt_found = true
			audio_format = raw_data[offset + 8] | (raw_data[offset + 9] << 8)
			num_channels = raw_data[offset + 10] | (raw_data[offset + 11] << 8)
			sample_rate = raw_data[offset + 12] | (raw_data[offset + 13] << 8) | (raw_data[offset + 14] << 16) | (raw_data[offset + 15] << 24)
			bits_per_sample = raw_data[offset + 22] | (raw_data[offset + 23] << 8)
			write_log("WAV fmt: format=%d channels=%d sample_rate=%d bits=%d" % [audio_format, num_channels, sample_rate, bits_per_sample])
		elif chunk_id == "data":
			data_offset = offset + 8
			data_size = chunk_size
			write_log("WAV data chunk: offset=%d size=%d" % [data_offset, data_size])
			break  # Found data chunk, stop searching
		
		offset += 8 + chunk_size
		# Align to even boundary
		if chunk_size % 2 != 0:
			offset += 1
	
	if not fmt_found:
		write_log("ERROR: WAV fmt chunk not found")
		return null
	
	if data_offset == 0:
		write_log("ERROR: WAV data chunk not found")
		return null
	
	# Extract raw PCM data (skip WAV header) - will be converted if needed
	var pcm_data = raw_data.slice(data_offset, data_offset + data_size)
	
	# Map WAV format to AudioStreamWAV format
	# AudioStreamWAV.Format: FORMAT_8_BITS=0, FORMAT_16_BITS=1, FORMAT_IMA_ADPCM=2, FORMAT_QOA=3
	
	if audio_format == 1:  # PCM
		if bits_per_sample == 8:
			stream.format = AudioStreamWAV.FORMAT_8_BITS
		elif bits_per_sample == 16:
			stream.format = AudioStreamWAV.FORMAT_16_BITS
		elif bits_per_sample == 24:
			# Convert 24-bit PCM to 16-bit (Godot doesn't support 24-bit)
			pcm_data = _convert_24bit_to_16bit(pcm_data)
			stream.format = AudioStreamWAV.FORMAT_16_BITS
			write_log("Converted 24-bit PCM to 16-bit: new data_size=%d" % pcm_data.size())
		elif bits_per_sample == 32:
			# Convert 32-bit PCM to 16-bit
			pcm_data = _convert_32bit_to_16bit(pcm_data)
			stream.format = AudioStreamWAV.FORMAT_16_BITS
			write_log("Converted 32-bit PCM to 16-bit: new data_size=%d" % pcm_data.size())
		else:
			write_log("ERROR: Unsupported PCM bit depth: %d" % bits_per_sample)
			return null
	elif audio_format == 3:  # IEEE float - convert to 16-bit
		if bits_per_sample == 32:
			pcm_data = _convert_float32_to_16bit(pcm_data)
			stream.format = AudioStreamWAV.FORMAT_16_BITS
			write_log("Converted 32-bit float PCM to 16-bit: new data_size=%d" % pcm_data.size())
		else:
			write_log("ERROR: Unsupported float bit depth: %d" % bits_per_sample)
			return null
	else:
		write_log("ERROR: Unsupported WAV audio format: %d" % audio_format)
		return null
	
	stream.data = pcm_data
	stream.mix_rate = sample_rate
	stream.stereo = (num_channels == 2)
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	write_log("Created AudioStreamWAV: format=%d mix_rate=%d stereo=%s data_size=%d" % [stream.format, stream.mix_rate, str(stream.stereo), stream.data.size()])
	return stream

func _create_mp3_stream(raw_data: PackedByteArray) -> AudioStreamMP3:
	"""Create AudioStreamMP3 from raw MP3 bytes."""
	var stream = AudioStreamMP3.new()
	stream.data = raw_data
	write_log("Created AudioStreamMP3: data_size=%d" % stream.data.size())
	return stream

func _convert_24bit_to_16bit(data: PackedByteArray) -> PackedByteArray:
	"""Convert 24-bit PCM samples to 16-bit by taking the upper 16 bits of each sample."""
	var result = PackedByteArray()
	result.resize(data.size() * 2 / 3)  # 16-bit = 2 bytes per sample, 24-bit = 3 bytes
	var out_idx = 0
	var i = 0
	while i + 2 < data.size():
		# 24-bit little-endian: [low] [mid] [high]
		# Take upper 16 bits (mid, high) - this preserves the most significant bits
		result[out_idx] = data[i + 1]      # mid byte
		result[out_idx + 1] = data[i + 2]  # high byte
		i += 3
		out_idx += 2
	result.resize(out_idx)
	return result

func _convert_32bit_to_16bit(data: PackedByteArray) -> PackedByteArray:
	"""Convert 32-bit integer PCM samples to 16-bit by taking the upper 16 bits."""
	var result = PackedByteArray()
	result.resize(data.size() / 2)  # 16-bit = 2 bytes, 32-bit = 4 bytes
	var out_idx = 0
	var i = 0
	while i + 3 < data.size():
		# 32-bit little-endian: [b0] [b1] [b2] [b3]
		# Take upper 16 bits (b2, b3)
		result[out_idx] = data[i + 2]
		result[out_idx + 1] = data[i + 3]
		i += 4
		out_idx += 2
	result.resize(out_idx)
	return result

func _convert_float32_to_16bit(data: PackedByteArray) -> PackedByteArray:
	"""Convert 32-bit float PCM samples to 16-bit integer."""
	var result = PackedByteArray()
	var num_samples = data.size() / 4
	result.resize(num_samples * 2)
	var out_idx = 0
	for s in range(num_samples):
		var offset = s * 4
		# Decode IEEE 754 float from bytes (little-endian)
		var bits = data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16) | (data[offset + 3] << 24)
		var sign = 1.0 if (bits & 0x80000000) == 0 else -1.0
		var exponent = (bits >> 23) & 0xFF
		var mantissa = float(bits & 0x7FFFFF)
		var value: float
		if exponent == 0:
			value = sign * mantissa * pow(2.0, -149.0)
		elif exponent == 255:
			value = 0.0  # Inf/NaN -> silence
		else:
			value = sign * (mantissa + 8388608.0) * pow(2.0, exponent - 150.0)
		# Clamp to [-1.0, 1.0] and convert to 16-bit
		var int_val = int(clampf(value, -1.0, 1.0) * 32767.0)
		# Store as 16-bit little-endian
		result[out_idx] = int_val & 0xFF
		result[out_idx + 1] = (int_val >> 8) & 0xFF
		out_idx += 2
	return result

func write_log(msg: String):
	var timestamp = "%.2f" % elapsed
	print("[%s] %s" % [timestamp, msg])
	if log_file:
		log_file.store_line("[%s] %s" % [timestamp, msg])
		log_file.flush()
