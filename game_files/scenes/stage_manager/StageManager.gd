extends Node

const stages = ["res://scenes/menu/MainMenu.tscn",
			"res://scenes/world_map/WorldMap.tscn",
			"res://scenes/story/Begin.tscn",
			"res://scenes/stages/StageTutorial.tscn",
			"res://scenes/stages/Stage1.tscn",
			"res://scenes/stages/Stage2.tscn",
			"res://scenes/stages/Stage3.tscn",
			"res://scenes/menu/Credits.tscn",
			"res://scenes/stages/BonusStage.tscn",
			"res://scenes/stages/StageDialog.tscn",
			"res://scenes/stages/BonusStageMobile.tscn",
			"res://scenes/story/EndGameAnimation.tscn",
			];

const stage_indexes = {
	"main_menu" : 0,
	"world_map" : 1,
	"story" : 2,
	"tutorial" : 3,
	"stage_1" : 4,
	"stage_2": 5,
	"stage_3": 6,
	"credits" : 7,
	"bonus" : 8,
	"gallery_tutorial" : 9,
	"bonus_mobile" : 10,
	"end_animation" : 11,
}

const control_mobile = preload("res://scenes/mobile_control/mobile_control.tscn");

onready var gv = Global_variable

var current_stage
var current_idx = 0
var last_stage
var last_idx
var mobile_control_node
var _keep_loading_hidden : bool
var _old_volume

var checkpointed = false


func reset_stage():
	change_stage(current_stage)


func change_stage(name : String, keep_loading_hidden: bool = false):
	_keep_loading_hidden = keep_loading_hidden
	if stage_indexes.has(name):
		last_idx = current_idx
		last_stage = current_stage
		
		current_idx = stage_indexes[name]
		current_stage = name
		DJ.play_with_fade_in(name)
		change_stage_idx(current_idx)
		if last_idx == 1:
			Global_variable.last_stage_number = current_idx-3
		if last_idx > 2 and last_idx < 7 :
			print("LAST_STAGE",last_idx-3)
			Global_variable.last_stage_number = last_idx-3


func change_stage_idx(idx : int):
	show_loading()
	
	if self.get_child_count() > 0:
		var old_stage = self.get_child(0);
		# self.remove_child(old_stage);
		old_stage.queue_free()
	
	StageLoader.goto_scene(stages[idx])
	yield(StageLoader, "resource_loaded")
	var stage = StageLoader.resource
	
	var _new = stage.instance()
	
	self.add_child(_new);
	for signall in _new.get_signal_list():
		if "change_scene" == signall["name"]:
			_new.connect("change_scene", self, "change_stage")
	
	hide_loading()


func get_stage_number() -> int:
	return current_idx-4;


func get_last_stage_number() -> int:
	return last_idx-4;


func set_checkpointed(new):
	checkpointed = new


func get_checkpointed():
	return checkpointed


func _get_main_node():
	return get_tree().root.get_node("MainNode")


func show_loading():
	if !_keep_loading_hidden:
		_get_main_node().show_loading_screen()
	_disable_sound()
	Global_variable.mobile_control_node.hide_pause_button()


func hide_loading():
	_enable_sound()
	if !_keep_loading_hidden:
		_get_main_node().hide_loading_screen()

func _disable_sound():
	_old_volume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(0))

func _enable_sound():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), _old_volume)
