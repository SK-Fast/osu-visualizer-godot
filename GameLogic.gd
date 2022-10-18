extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var selectSongMenu = $SelectSong

var spectrum

const FREQ_MAX = 11050.0

const WIDTH = 400
const HEIGHT = 100

const MIN_DB = 60
const BARS_LOOP = 20

var visBars = []
var visualizer_offset = 0
var tmp_vis_offset = 0
var oldRectScales = []
var prev_beat_height = 0
var first_time_kiai = false

var audioPlayer

func _draw():
	#warning-ignore:integer_division
	
	if not spectrum:
		return
	
	var barsCount = visBars.size()
	var rectScales = []
	
	var prev_hz = 0
	
	var barIndex = 0
	
	for i in range(0, BARS_LOOP):
		var hz = 1 * FREQ_MAX / barsCount;
		var magnitude: float = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy = clamp((MIN_DB + linear2db(magnitude)) / MIN_DB, 0, 1)
		var height = (energy * HEIGHT) / 50
		
		if i == visualizer_offset:
			if oldRectScales.size() > 0:
				if height > oldRectScales[i]:
					rectScales.append(height)
				else:
					rectScales.append(oldRectScales[i] - 0.01)
			else:
				rectScales.append(height)
			
			# Emit Kiai Particles
			if abs(height - prev_beat_height) > 1 and prev_beat_height < 0.15:
				first_time_kiai = false
				
				$Emit1/Emit1.emitting = true
				$Emit2/Emit2.emitting = true
				
			prev_beat_height = height

		else:
			if oldRectScales.size() > 0:
				if oldRectScales[i] > 0:
					rectScales.append(oldRectScales[i] - 0.01)
				else:
					rectScales.append(0)
			else:
				rectScales.append(0)
		
		prev_hz = hz
	
	oldRectScales = rectScales
	
	tmp_vis_offset = tmp_vis_offset + 0.5
	
	if tmp_vis_offset >= 1:
		visualizer_offset = visualizer_offset + 1
		tmp_vis_offset = 0
	
	if visualizer_offset > BARS_LOOP:
		visualizer_offset = 0
	
	var loop_counter = 0
	
	for i in range(0, barsCount):
		var bar = visBars[i]
		var height = rectScales[loop_counter]
		
		bar.rect_scale = Vector2(1, height)
		
		loop_counter = loop_counter + 1
		
		if loop_counter >= BARS_LOOP:
			loop_counter = 0
		
func _on_SelectSong_pressed():
	var fileDialog = FileDialog.new()
	
	fileDialog.access = FileDialog.ACCESS_FILESYSTEM
	fileDialog.mode = FileDialog.MODE_OPEN_FILE
	
	fileDialog.window_title = "Select da song"
	fileDialog.add_filter("*.mp3")
	fileDialog.add_filter("*.ogg")
	
	add_child(fileDialog)
	fileDialog.show()
	fileDialog.resizable = true
	fileDialog.rect_size = Vector2(450,350)
	fileDialog.popup_centered()
	
	fileDialog.connect("file_selected", self, "_song_selected")
	
	OS.set_window_mouse_passthrough([])

func _song_selected(path):
	
	prev_beat_height = 0
	
	first_time_kiai = true
	
	if audioPlayer == null:
		audioPlayer = AudioStreamPlayer.new()
	else:
		audioPlayer.stop()
	
	var audio_loader = AudioLoader.new()
	var audioStream: AudioStream = audio_loader.loadfile(path)
	
	audioPlayer.set_stream(audioStream)
	
	add_child(audioPlayer)
	audioPlayer.play()
	
	$AnimPlay.play("bump")
	OS.set_window_mouse_passthrough(PoolVector2Array([0,30]))

func _process(_delta):
	update()

func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("song_select"):
			_on_SelectSong_pressed()

func create_bars():
	for i in range(0,180,3):
		var visualizerBar = preload("res://VisualizerBar.tscn").instance()
		
		visualizerBar.rect_rotation = i
		
		$Logo/Visualizers/VisualizerContainer.add_child(visualizerBar)
		
		visBars.append(visualizerBar)

func _ready():
	get_tree().get_root().set_transparent_background(true)
	OS.set_window_maximized(true)

	spectrum = AudioServer.get_bus_effect_instance(0,0)
	
	create_bars()
	
	$StartupAnim.play("startup")

func on_bump():
	return
	
	var visualizerClone = $Logo/Visualizers/VisualizerContainer.duplicate()
	
	$Logo/Visualizers.add_child(visualizerClone)
	
	var tween = Tween.new()
	add_child(tween)
	
	for item in visualizerClone.get_children():
		tween.interpolate_property(item, "rect_scale",
			item.rect_scale, Vector2(1, 0), 1,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	tween.start()
