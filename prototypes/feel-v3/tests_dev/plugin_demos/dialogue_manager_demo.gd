extends Node
## Demo: load a .dialogue file and read its first line + choices.
## Real use: DialogueManager.show_dialogue_balloon(load("res://.../x.dialogue"), "start").
func _ready() -> void:
	var res: Resource = load("res://tests_dev/plugin_demos/demo.dialogue")
	var line: DialogueLine = await DialogueManager.get_next_dialogue_line(res, "start")
	var choices: Array = []
	for r: DialogueResponse in line.responses:
		choices.append(r.text)
	print("DIALOGUE_DEMO who=%s text=%s choices=%s pass=%s" % [line.character, line.text, str(choices), str(line.character == "Warden" and choices.size() == 2)])
	get_tree().quit()
