# PROTOTYPE - NOT FOR PRODUCTION
# Screenshot harness: loads each scene, waits, saves a PNG. Throwaway.
extends Node2D


func _ready() -> void:
	await RenderingServer.frame_post_draw
	for s in ["menu", "duel", "cache", "denial"]:
		var sc = load("res://%s.tscn" % s).instantiate()
		add_child(sc)
		for i in 40:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img: Image = get_viewport().get_texture().get_image()
		img.save_png("res://shot_%s.png" % s)
		print("SHOT ", s)
		sc.queue_free()
		for i in 6:
			await get_tree().process_frame

	# the death surface, over the cache room
	var cache_scene = load("res://cache.tscn").instantiate()
	add_child(cache_scene)
	for i in 30:
		await get_tree().process_frame
	var bb := BackBufferCopy.new()
	bb.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	cache_scene.add_child(bb)
	var off = load("res://offline.gd").new()
	off.cause = "FAULT: THE PIT · ENVIRONMENT · TICK 214"
	off.has_module = true
	off.held_ms = 600.0
	cache_scene.add_child(off)
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img2: Image = get_viewport().get_texture().get_image()
	img2.save_png("res://shot_offline.png")
	print("SHOT offline")
	get_tree().quit()
