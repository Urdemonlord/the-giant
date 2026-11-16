extends Node
## Autoload: status shift global THE GIANT.
## Sanity turun saat melihat hal yang tidak seharusnya ada.
## Stability turun saat pos dibiarkan gelap / generator mati.

signal sanity_changed(value: float)
signal stability_changed(value: float)
signal generator_changed(is_on: bool, fuel: float)
signal task_completed(task_id: String)
signal clock_changed(minutes_from_start: float)
signal message_shown(text: String)
signal shift_ended(success: bool)

const SHIFT_START_HOUR := Balance.SHIFT_START_HOUR
const SHIFT_LENGTH_MINUTES := Balance.SHIFT_LENGTH_MINUTES # 22:00 -> 06:00
## 1 detik dunia nyata = 1 menit waktu shift (shift penuh +/- 8 menit).
const MINUTES_PER_SECOND := Balance.MINUTES_PER_SECOND

var sanity: float = Balance.MAX_SANITY
var stability: float = Balance.MAX_STABILITY
var generator_on: bool = false
var fuel: float = Balance.MAX_FUEL
var door_open: bool = false
var shift_minutes: float = 0.0
var shift_over: bool = false

var tasks: Dictionary = {
	"generator": {"label": "Nyalakan generator", "done": false},
	"radio": {"label": "Cek radio pos", "done": false},
	"log": {"label": "Tulis laporan di buku jaga", "done": false},
	"hunter": {"label": "Lewati kunjungan pemburu", "done": false},
	"survive": {"label": "Bertahan sampai 06:00", "done": false},
}

## Diisi menu utama sebelum pindah scene kalau pemain memilih "Lanjutkan".
## main.gd menerapkannya di _ready, lalu mengosongkannya.
var resume_data: Dictionary = {}

func _ready() -> void:
	reset_shift()

func reset_shift() -> void:
	sanity = Balance.MAX_SANITY
	stability = Balance.MAX_STABILITY
	generator_on = false
	fuel = Balance.MAX_FUEL
	door_open = false
	shift_minutes = 0.0
	shift_over = false
	for id in tasks.keys():
		tasks[id]["done"] = false
	sanity_changed.emit(sanity)
	stability_changed.emit(stability)
	generator_changed.emit(generator_on, fuel)
	clock_changed.emit(shift_minutes)

func show_message(text: String) -> void:
	message_shown.emit(text)

func damage_sanity(amount: float) -> void:
	if shift_over:
		return
	sanity = clampf(sanity - amount, 0.0, Balance.MAX_SANITY)
	sanity_changed.emit(sanity)
	if sanity <= 0.0:
		_end_shift(false)

func restore_sanity(amount: float) -> void:
	sanity = clampf(sanity + amount, 0.0, Balance.MAX_SANITY)
	sanity_changed.emit(sanity)

func damage_stability(amount: float) -> void:
	if shift_over:
		return
	stability = clampf(stability - amount, 0.0, Balance.MAX_STABILITY)
	stability_changed.emit(stability)
	if stability <= 0.0:
		_end_shift(false)

func restore_stability(amount: float) -> void:
	stability = clampf(stability + amount, 0.0, Balance.MAX_STABILITY)
	stability_changed.emit(stability)

func set_generator(on_state: bool) -> void:
	generator_on = on_state and fuel > 0.0
	generator_changed.emit(generator_on, fuel)
	if generator_on:
		complete_task("generator")

func drain_fuel(amount: float) -> void:
	if not generator_on:
		return
	fuel = clampf(fuel - amount, 0.0, Balance.MAX_FUEL)
	if fuel <= 0.0:
		generator_on = false
		show_message("Generator mati. Bahan bakar habis.")
	generator_changed.emit(generator_on, fuel)

func complete_task(task_id: String) -> void:
	if not tasks.has(task_id):
		return
	if tasks[task_id]["done"]:
		return
	tasks[task_id]["done"] = true
	task_completed.emit(task_id)

func is_task_done(task_id: String) -> bool:
	return tasks.has(task_id) and bool(tasks[task_id]["done"])

func advance_time(delta_seconds: float) -> void:
	if shift_over:
		return
	shift_minutes += delta_seconds * MINUTES_PER_SECOND
	clock_changed.emit(shift_minutes)
	if shift_minutes >= SHIFT_LENGTH_MINUTES:
		complete_task("survive")
		_end_shift(sanity > 0.0 and stability > 0.0)

func clock_text() -> String:
	return clock_text_for(shift_minutes)

func clock_text_for(minutes: float) -> String:
	var total := int(SHIFT_START_HOUR * 60.0 + minutes) % (24 * 60)
	return "%02d:%02d" % [total / 60, total % 60]

func _end_shift(success: bool) -> void:
	if shift_over:
		return
	shift_over = true
	shift_ended.emit(success)
