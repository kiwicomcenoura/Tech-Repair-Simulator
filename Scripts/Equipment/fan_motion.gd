extends RefCounted
## A rotor state per component group, shared by all fans of that group.

const GROUPS := ["case", "cooling", "gpu", "psu"]
var _pc_id := ""
var _clock := 0.0
var _speed := {}
var _phase := {}


func advance(ledger: RefCounted, pc_id: String, delta: float) -> bool:
	if pc_id != _pc_id:
		_pc_id = pc_id
		_clock = 0.0
		_speed.clear()
		_phase.clear()
	_clock += delta
	var moving := false
	for group in GROUPS:
		var previous: float = _speed.get(group, 0.0)
		var target: float = ledger.fan_speed(pc_id, group, _clock)
		var value := move_toward(previous, target, delta * (12.0 if target > previous else 8.0))
		_speed[group] = value
		if previous == 0.0 and value == 0.0: continue
		_phase[group] = fposmod(phase(group) + TAU * value * delta, TAU)
		moving = true
	return moving


func phase(group: String, index: int = 0) -> float:
	return float(_phase.get(group, 0.0)) + index * 0.38


func speed(group: String) -> float:
	return _speed.get(group, 0.0)
