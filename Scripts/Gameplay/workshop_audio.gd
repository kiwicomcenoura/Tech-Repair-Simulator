extends Node
## Short original effects synthesized once at startup as 16-bit PCM.

const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const SAMPLE_RATE := 22050
# Segments contain duration, start/end frequency, and the amount of filtered noise.
const CUES := {
	"click": [[0.038, 780.0, 460.0, 0.42]],
	"pickup": [[0.068, 225.0, 320.0, 0.60]],
	"place": [[0.10, 164.0, 58.0, 0.68]],
	"package": [[0.075, 290.0, 140.0, 0.93], [0.065, 170.0, 90.0, 0.92]],
	"screw": [[0.030, 985.0, 520.0, 0.63], [0.057, 650.0, 260.0, 0.61]],
	"unscrew": [[0.052, 810.0, 510.0, 0.75], [0.048, 720.0, 445.0, 0.79], [0.043, 645.0, 390.0, 0.81], [0.056, 435.0, 190.0, 0.58]],
	"cable_click": [[0.014, 1760.0, 1050.0, 0.59], [0.032, 840.0, 380.0, 0.37]],
	"latch": [[0.056, 615.0, 260.0, 0.53]],
	"power_on": [[0.18, 92.0, 233.0, 0.52]],
	"power_off": [[0.15, 178.0, 65.0, 0.48]],
	"boot_ok": [[0.095, 520.0, 520.0, 0.04], [0.15, 785.0, 785.0, 0.04]],
	"boot_fail": [[0.12, 290.0, 275.0, 0.10], [0.11, 180.0, 162.0, 0.10]],
	"error": [[0.09, 254.0, 175.0, 0.26]],
	"purchase": [[0.077, 615.0, 615.0, 0.06], [0.15, 925.0, 925.0, 0.03]],
	"delivery": [[0.085, 390.0, 418.0, 0.03], [0.14, 523.0, 544.0, 0.05]],
}
static var _instance: Node
var _players: Dictionary = {}


func _ready() -> void:
	_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	for cue in CUES:
		var player := AudioStreamPlayer.new()
		player.stream = _synthesize(CUES[cue])
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
	var gain := 0.16 if cue == "click" else 0.29
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
		var filtered_noise := 0.0
		for i in range(sample_count):
			var fraction := float(i) / float(sample_count - 1)
			phase += TAU * lerpf(segment[1], segment[2], fraction) / SAMPLE_RATE
			filtered_noise = lerpf(filtered_noise, random.randf_range(-1.0, 1.0), 0.44)
			var envelope := minf(fraction * 25.0, 1.0) * pow(1.0 - fraction, 1.5)
			var sample := lerpf(sin(phase) * 0.75 + sin(phase * 2.0) * 0.18, filtered_noise, segment[3])
			pcm.encode_s16(offset + 2 * i, roundi(sample * envelope * 30000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = pcm
	return stream
