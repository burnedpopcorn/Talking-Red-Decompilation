extends Node2D

onready var mic = $Microphone
onready var red = $Red
onready var red_voice = $"Red Voice"
onready var text = $CanvasLayer / DBGText
onready var show_dbg = $CanvasLayer / Settings / ShowDebug


onready var settings_highlight = $CanvasLayer / Highlights / HighlightSettings
onready var settings_root = $CanvasLayer / Settings
onready var sensitivity_display = $CanvasLayer / Settings / SensitivityDisplay
onready var sensitivity_slider = $CanvasLayer / Settings / SliderSensitivity

var samples = []
export  var sample_limit = 10

export  var talking_wait_time = 1.2
export  var over_talk_db_loud = 10


var red_idx
var cap_idx


func _ready():
	text.visible = show_dbg.pressed
	
	red.play("default")
	
	cap_idx = AudioServer.get_bus_index("Capture")
	red_idx = AudioServer.get_bus_index("RedVoice")
	
	noise_floor = sensitivity_slider.value
	
	settings_root.hide()

var talk_timer = 0
var talk_timer_running
var talking
var talking_prev

var noise_floor = - 75


func _process(delta):
	text.text = ""
	
	get_audio_sample()
	
	var vol = round(linear2db(get_volume_avg(samples)))
	
	sensitivity_display.value = vol
	
	text.text += "noise floor: " + str(noise_floor)
	text.text += "\nheard: " + str(vol)
	text.text += "\nquiet timer: " + str(talk_timer)
	
	if check_speak_animation():
		return 
	
	
	if not red_voice.playing:
		talking = vol > noise_floor
	
	
	if not talking and talking_prev:
		talk_timer_running = true
	
	if talking and not talking_prev:
		talk_timer_running = false
		talk_timer = 0.0
	
	
	if talk_timer_running:
		if red_voice.playing:
			talk_timer_running = false
			talk_timer = 0
		elif talk_timer >= talking_wait_time:
			talk_timer_running = false
			red_voice.play(0)
			talk_timer = 0
		else :
			talk_timer += delta
	
	set_listening_sprite(vol)
	
	talking_prev = talking


func get_audio_sample():
	var sample = db2linear(AudioServer.get_bus_peak_volume_left_db(cap_idx, 0))
	
	samples.append(sample)
	
	if samples.size() > sample_limit:
		samples.pop_front()

func check_speak_animation()->bool:
	if red_voice.playing:
		var mouth_sample = db2linear(AudioServer.get_bus_peak_volume_left_db(red_idx, 0)) * 100
		
		if mouth_sample > rand_range(2, 30):
			red.play("talking2")
		else :
			red.play("talking1")
		
		return true
	
	return false

func set_listening_sprite(vol):
	if talking or talk_timer > 0 and talk_timer < talking_wait_time:
		red_voice.stop()
		
		if vol > noise_floor + over_talk_db_loud:
			red.play("listening loud")
		else :
			red.play("listening")
		
	else :
		if not red_voice.playing:
			red.play("default")

func get_volume_avg(audio_samples)->float:
	var avg = 0
	
	for sample in audio_samples:
		avg += sample
	
	if avg != 0:
		return avg / audio_samples.size()
	else :
		return 0.0

func _on_microphone_finished():
	
	yield (get_tree(), "idle_frame")
	
	
	mic.play()


func _on_sensitivity_value_changed(value):
	noise_floor = value


func _on_settings_toggled(button_pressed):
	settings_root.visible = not settings_root.visible
	
	settings_highlight.visible = settings_root.visible




func _on_show_debug_toggled(button_pressed):
	text.visible = button_pressed
