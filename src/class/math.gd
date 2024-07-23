class_name Math

## Converts Time in [code]Seconds[/code] to [code]Beats[/code] Based off of a [code]BPM[/code]
static func secs_to_beats(seconds: float, bpm: float) -> float:
	return seconds / (60.0 / bpm)

## Converts Time in [code]Beats[/code] to [code]Seconds[/code] Based off of a [code]BPM[/code]
static func beats_to_secs(beats: float, bpm: float) -> float:
	return beats / (bpm / 60.0)

## Converts Time in [code]Seconds[/code] to [code]Beats[/code] Based off of an array of [code]BPMs[/code]
static func secs_to_beat_dynamic(seconds: float, bpms: Array = Config.keyframes['modifiers']) -> float:
	var idx = 1
	var cumulative_beats = 0.0
	var prev_timestamp = bpms[0]['timestamp']
	while idx < bpms.size():
		if bpms[idx]['timestamp'] > seconds:
			break
		cumulative_beats += (bpms[idx]['timestamp'] - prev_timestamp) * (bpms[idx-1]['bpm'] / 60.0)
		prev_timestamp = bpms[idx]['timestamp']
		idx += 1
	return cumulative_beats + ((seconds - bpms[idx-1]['timestamp']) * (bpms[idx-1]['bpm'] / 60.0))

## Converts Time in [code]Beats[/code] to [code]Seconds[/code] Based off of an array of [code]BPMs[/code]
static func beat_to_secs_dynamic(beats: float, bpms: Array = Config.keyframes['modifiers']) -> float:
	var idx = 1
	var cumulative_beats = 0.0
	var prev_beat = 0.0
	var prev_timestamp = bpms[0]['timestamp']
	while idx < bpms.size():
		cumulative_beats += (bpms[idx]['timestamp'] - prev_timestamp) * (bpms[idx-1]['bpm'] / 60.0)
		if cumulative_beats > beats:
			break
		prev_beat = cumulative_beats
		prev_timestamp = bpms[idx]['timestamp']
		idx += 1
	return bpms[idx-1]['timestamp'] + ((beats - prev_beat) * (60.0 / bpms[idx-1]['bpm']))
