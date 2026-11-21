extends Node
## Demo: register a debug command in LimboConsole and run it.
## In play: press ` (backtick), type `demo_heal 5`.
var hp: int = 1

func _ready() -> void:
	LimboConsole.register_command(demo_heal, "demo_heal", "Add HP to the demo player")
	LimboConsole.execute_command("demo_heal 5")
	print("LIMBO_CONSOLE_DEMO hp=%d pass=%s" % [hp, str(hp == 6)])
	get_tree().quit()

func demo_heal(amount: int) -> void:
	hp += amount
	LimboConsole.info("hp now %d" % hp)
