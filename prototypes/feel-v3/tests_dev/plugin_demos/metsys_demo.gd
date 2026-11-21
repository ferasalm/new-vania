extends Node2D
## Demo: MetSys draws a world map from its MapData.txt.
## Uses the plugin's sample map (SampleProject/Maps/MapData.txt) without changing project settings.
## Real use: draw OUR rooms in the MetSys map editor (bottom panel "MetSys"), then MetSys.make_map_view(...) for the map screen/minimap.
var map_view: RefCounted

func _ready() -> void:
	MetSys.load_map_data("res://SampleProject/Maps/MapData.txt")
	MetSys.reset_state()
	MetSys.set_save_data()
	var cells: Array = [Vector3i(-5,1,0), Vector3i(-4,1,0), Vector3i(-3,1,0), Vector3i(-2,1,0), Vector3i(-2,0,0), Vector3i(-2,-1,0), Vector3i(-1,-1,0), Vector3i(-1,0,0), Vector3i(0,-1,0), Vector3i(0,0,0), Vector3i(1,0,0), Vector3i(1,-1,0), Vector3i(2,-1,0), Vector3i(2,0,0)]
	for c: Vector3i in cells:
		MetSys.discover_cell(c)
	MetSys.visit_cell(Vector3i(0, 0, 0))
	position = Vector2(150, 110)
	map_view = MetSys.make_map_view(self, Vector2i(-6, -3), Vector2i(10, 6), 0)
	print("METSYS_DEMO explored=%s" % str(MetSys.get_explored_ratio(0)))
