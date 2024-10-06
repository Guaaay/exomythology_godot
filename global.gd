extends Node3D

var exo_id = 1
var planet_ra
var planet_dec

# Called when the node enters the scene tree for the first time.
func _ready():
	# Fetch the exo_id from the URL path
	exo_id = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('id')", true)
	# Fetch 'planet_ra' parameter
	planet_ra = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('planet_ra')", true)
	# Fetch 'planet_dec' parameter
	planet_dec = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('planet_dec')", true)
	
	# Check if both parameters are retrieved
	if planet_ra != null and planet_dec != null and exo_id != null:
		# Convert parameters to float and print them
		planet_ra = float(planet_ra)
		planet_dec = float(planet_dec)
		exo_id = int(exo_id)
		print("Parameters received: RA =", planet_ra, "DEC =", planet_dec, "EXO_ID = ", exo_id)
	else:
		exo_id = 0
		# Handle case when parameters are missing
		print("No valid RA/DEC parameters received")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
