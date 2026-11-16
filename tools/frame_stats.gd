extends Node
## Cek frame time CPU headless (performance-optimization Pattern 3):
## main.tscn, 60 frame pemanasan + 600 frame terukur, budget 16.6 ms.
## Headless TIDAK mengukur GPU (tidak ada renderer) — angka di sini
## cuma biaya script/fisika/engine. Jalankan:
## Godot --headless --path . res://tools/frame_stats.tscn
## Keluar 0 kalau p95 <= budget, 1 kalau di atas.

func _ready() -> void:
	OS.low_processor_usage_mode_sleep_usec = 0
	_run()

func _run() -> void:
	GameState.skip_intro = true
	var main: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	for i in range(60):
		await get_tree().process_frame
	var ms := PackedFloat64Array()
	var last := Time.get_ticks_usec()
	for i in range(600):
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		ms.append((now - last) / 1000.0)
		last = now
	ms.sort()
	var avg := 0.0
	for v in ms:
		avg += v / ms.size()
	var p95 := ms[int(ms.size() * 0.95)]
	var p99 := ms[int(ms.size() * 0.99)]
	var over := ms.size() - ms.bsearch(16.6, false)
	print("FRAME avg=%.2fms p95=%.2fms p99=%.2fms max=%.2fms over_budget=%d/%d"
		% [avg, p95, p99, ms[-1], over, ms.size()])
	get_tree().quit(1 if p95 > 16.6 else 0)
