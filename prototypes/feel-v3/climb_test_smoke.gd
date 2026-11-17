# PROTOTYPE - NOT FOR PRODUCTION
# Runs the normal self-test (smoke.gd) with Helper 2's proposed changes applied in
# memory: the player.gd wall-jump lines and the new smoke.gd checks. Nothing on disk
# is changed. It proves the exact lines in climb_test_patch.gd apply and pass together.
# Run: godot --headless --path prototypes/feel-v3 res://climb_test_smoke.tscn
# Option after "--":  smokeonly (new checks on today's player.gd: shows they catch the problem)
extends Node

const Patch := preload("res://climb_test_patch.gd")


func _ready() -> void:
	# RETIRED 2026-11-17: player.gd already has these lines, so the patch no longer applies.
	# Use smoke.tscn and climb_test.tscn instead.
	print("climb_test_smoke: retired (its patch is already in player.gd); run smoke.tscn and climb_test.tscn")
	get_tree().quit(0)
	return
	if not OS.get_cmdline_user_args().has("smokeonly"):
		if not Patch.take_over("res://player.gd", Patch.PLAYER):
			get_tree().quit(1)
			return
	var gs := Patch.script_from("res://smoke.gd", Patch.SMOKE)
	if gs == null:
		get_tree().quit(1)
		return
	print("patched in memory: res://smoke.gd (%d edits)" % Patch.SMOKE.size())
	var n := Node.new()
	n.set_script(gs)
	add_child(n)
