extends Node

var player : AudioStreamPlayer
var rng := RandomNumberGenerator.new()
var muted := true

var songs : Array = [
		load("res://misc/When I See You Again (Intro Nightcore) - Wiz Khalifa.mp3")
#		load("res://misc/o-monolith/1 Swing (In A Dream) - Squid.mp3"),
#		load("res://misc/o-monolith/2 Devil's Den - Squid.mp3"),
#		load("res://misc/o-monolith/3 Siphon Song - Squid.mp3"),
#		load("res://misc/o-monolith/4 Undergrowth - Squid.mp3"),
#		load("res://misc/o-monolith/5 The Blades - Squid.mp3"),
#		load("res://misc/o-monolith/6 After The Flash - Squid.mp3"),
#		load("res://misc/o-monolith/7 Green Light - Squid.mp3"),
#		load("res://misc/o-monolith/8 If You Had Seen The Bull's Swimming Attempts You Would Have Stayed Away - Squid.mp3"),
]
var old_songs : Array = []


func _ready():
	randomize()
	player = AudioStreamPlayer.new()
	add_child(player)
	player.connect("finished", _on_player_finished)
	play_random()


func play_random():
	if muted: return
	if songs.size() == 0:
		songs = old_songs
		old_songs = []
	var number = rng.randi_range(0, songs.size() - 1)
	player.stream = songs[number]
	old_songs.push_front(songs[number])
	songs.remove_at(number)
	player.play()


func _on_player_finished():
	play_random()
