extends Label

func _ready() -> void:
	print("Created label")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	text = "FPS: %s" % [Engine.get_frames_per_second()]
