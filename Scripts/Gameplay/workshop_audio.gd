extends Node
## Short original effects synthesized once at startup as 16-bit PCM.

const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const SAMPLE_RATE := 22050
const ATTACK_SAMPLES := 0.010 * SAMPLE_RATE
# Segments contain duration, start/end frequency, and the amount of filtered noise.
const CUES := {
	"click": {"gain": 0.10, "segments": [[0.046, 620.0, 405.0, 0.29]]},
	"pickup": {"gain": 0.18, "segments": [[0.074, 230.0, 315.0, 0.48]]},
	"place": {"gain": 0.20, "segments": [[0.11, 148.0, 74.0, 0.56]]},
	"package": {"gain": 0.21, "segments": [[0.082, 260.0, 135.0, 0.85], [0.074, 160.0, 85.0, 0.87]]},
	"screw": {"gain": 0.17, "segments": [[0.038, 710.0, 440.0, 0.55], [0.065, 510.0, 250.0, 0.60]]},
	"unscrew": {"gain": 0.19, "segments": [
		[0.052, 650.0, 435.0, 0.72], [0.048, 580.0, 390.0, 0.76],
		[0.043, 510.0, 330.0, 0.77], [0.056, 380.0, 190.0, 0.61],
	]},
	"cable_click": {"gain": 0.15, "segments": [[0.026, 950.0, 650.0, 0.53], [0.044, 600.0, 355.0, 0.38]]},
	"latch": {"gain": 0.17, "segments": [[0.062, 510.0, 245.0, 0.54]]},
	"power_on": {"gain": 0.21, "segments": [[0.18, 92.0, 215.0, 0.49]]},
	"power_off": {"gain": 0.19, "segments": [[0.15, 166.0, 65.0, 0.46]]},
	"boot_ok": {"gain": 0.19, "segments": [[0.095, 440.0, 440.0, 0.04], [0.15, 659.25, 659.25, 0.04]]},
	"boot_fail": {"gain": 0.16, "segments": [[0.12, 261.0, 249.0, 0.10], [0.11, 185.0, 173.0, 0.10]]},
	"error": {"gain": 0.13, "segments": [[0.10, 235.0, 170.0, 0.22]]},
	"purchase": {"gain": 0.18, "segments": [[0.085, 523.25, 523.25, 0.06], [0.15, 783.99, 783.99, 0.03]]},
	"delivery": {"gain": 0.18, "segments": [[0.09, 392.0, 415.0, 0.03], [0.14, 523.0, 539.0, 0.05]]},
	"hdd_click": {"gain": 0.16, "segments": [[0.047, 118.0, 67.0, 0.84], [0.08, 55.0, 46.0, 0.24], [0.054, 132.0, 50.0, 0.91]]},
	"fan_rattle": {"gain": 0.13, "segments": [[0.23, 75.0, 89.0, 0.54], [0.14, 100.0, 64.0, 0.59]]},
}
static var _instance: Node
var _players: Dictionary = {}


func _ready() -> void:
	_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	for cue in CUES:
		var player := AudioStreamPlayer.new()
		player.stream = _synthesize(CUES[cue].segments)
		add_child(player)
		_players[cue] = player
	get_tree().node_added.connect(_watch_button)


func _exit_tree() -> void:
	for player in _players.values(): player.stop()


static func play(cue: String) -> void:
	if cue.is_empty() or not is_instance_valid(_instance) or Prefs.effects_volume <= 0.0: return
	_instance._play_cue(cue)


func _watch_button(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play.bind("click"))


func _play_cue(cue: String) -> void:
	var player: AudioStreamPlayer = _players.get(cue)
	if player == null or player.playing: return
	var gain: float = CUES[cue].gain
	player.volume_db = linear_to_db(Prefs.effects_volume * gain)
	player.play()


func _synthesize(segments: Array) -> AudioStreamWAV:
	var pcm := PackedByteArray()
	var random := RandomNumberGenerator.new()
	random.seed = 42819
	for segment in segments:
		var sample_count := roundi(segment[0] * SAMPLE_RATE)
		var offset := pcm.size()
		pcm.resize(offset + 2 * sample_count)
		var phase := 0.0
		var noise := 0.0
		var filtered_noise := 0.0
		for i in range(sample_count):
			var fraction := float(i) / float(sample_count - 1)
			phase += TAU * lerpf(segment[1], segment[2], fraction) / SAMPLE_RATE
			noise = lerpf(noise, random.randf_range(-1.0, 1.0), 0.25)
			filtered_noise = lerpf(filtered_noise, noise, 0.25)
			var attack := smoothstep(0.0, ATTACK_SAMPLES, float(i))
			var decay := 1.0 - smoothstep(0.0, 1.0, fraction)
			var tone := sin(phase) * 0.75 + sin(phase * 2.0) * 0.07
			var sample := lerpf(tone, filtered_noise, segment[3])
			pcm.encode_s16(offset + 2 * i, roundi(sample * attack * decay * 30000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = pcm
	return stream
