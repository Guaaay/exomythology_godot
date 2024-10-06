extends Node3D

@onready var httpRequest = $RequestConst
@onready var postConst = $PostConst
@onready var starRenderer = %StarRenderer
@onready var line = preload("res://const_line.tscn")
var constellations = [] 
var constellations_ready = false
var stars_ready = false
var done = false
var response = ""
var json = JSON.new()
var star_dict = {}
var current_line = null 

func generate_line(star1,star2):
	current_line = line.instantiate()
	scale_line(star1, star2)
	current_line.scale.x *= 1
	current_line.scale.z *= 1
	add_child(current_line)

func scale_line(point1: Vector3, point2: Vector3):
	if current_line == null:
		return

	var dir = point2 - point1
	var length = dir.length()
	var mid_point = (point1 + point2) * 0.5
	# Position the cylinder at the midpoint
	current_line.position = mid_point
	# Scale the cylinder to match the length between the two points
	# Assuming the default cylinder height is 2 units
	current_line.scale.y = length * 0.5
	# Align the cylinder's Y-axis with the direction vector
	var up_vector = Vector3.UP
	var target_dir = dir.normalized()
	var rotation_quat = Quaternion(up_vector, target_dir)
	# Apply the rotation to the cylinder
	current_line.rotation = rotation_quat.get_euler()
	
func post_constellation(constellation_data):
	var json_const = JSON.new()
	var constellation_json = json_const.stringify(constellation_data)
	postConst.request_completed.connect(_on_request_completed_post_const)
	httpRequest.timeout = 30  # 30 seconds timeout
	
	var error = httpRequest.request("https://api.exomythology.earth/api/constellations","",HTTPClient.METHOD_POST,constellation_json)
		
		
	
# Called when the node enters the scene tree for the first time.
func _ready():
	httpRequest.request_completed.connect(_on_request_completed_const)
	httpRequest.timeout = 30  # 30 seconds timeout
	var error = httpRequest.request("https://api.exomythology.earth/api/constellations")
	pass # Replace with function body.

func _on_request_completed_post_const(result, response_code, headers, body):
	print("Response code: ", response_code)
	
	if response_code == 307:
		print("Redirecting...")

		# Find the 'Location' header to get the new URL
		var new_url = ""
		for header in headers:
			print(header)
			if header.begins_with("location:"):
				new_url = header.substr(10).strip_edges()  # Get the URL from the 'Location' header
				break
		
		if new_url != "":
			# Make a new request to the redirected URL
			print("Redirected to: ", new_url)
			var error = httpRequest.request(new_url)
			if error != OK:
				print("Error making request to redirected URL: ", error)
		else:
			print("Error: Location header not found in 307 response.")
	elif response_code == 200:
		var json_string = body.get_string_from_utf8()
		response = json_string
		


func _on_request_completed_const(result, response_code, headers, body):
	print("Response code: ", response_code)
	
	if response_code == 307:
		print("Redirecting...")

		# Find the 'Location' header to get the new URL
		var new_url = ""
		for header in headers:
			print(header)
			if header.begins_with("location:"):
				new_url = header.substr(10).strip_edges()  # Get the URL from the 'Location' header
				break
		
		if new_url != "":
			# Make a new request to the redirected URL
			print("Redirected to: ", new_url)
			var error = httpRequest.request(new_url)
			if error != OK:
				print("Error making request to redirected URL: ", error)
		else:
			print("Error: Location header not found in 307 response.")
	elif response_code == 200:
		var json_string = body.get_string_from_utf8()
		response = json_string
		constellations_ready = true
		

#Expect an array of star pairs
func render_constellation(constellation):
	print("render_constellation")
	constellation = [["498143952104127104", "955717673191079936"]]
	var star1 = Vector3(0,0,0);
	var star2 = Vector3(0,0,0);
	for star_pair in constellation:
		for child in starRenderer.get_children():
			if int(child.star_id)==int(star_pair[0]):
				if(star1==Vector3(0,0,0)):
					star1 =  child.get_star_pos()
				elif(star2==Vector3(0,0,0)):
					star2 =  child.get_star_pos()
			elif int(child.star_id)==int(star_pair[1]):
				if(star1==Vector3(0,0,0)):
					star1 =  child.get_star_pos()
				elif(star2==Vector3(0,0,0)):
					star2 =  child.get_star_pos()		
		generate_line(star1,star2)
		

func render_constellations():
	var error = json.parse(response)
	if error == OK:
		var const_list = json.data
	else:
		print("ERROR")
		return []
	for constellation in constellations:
		render_constellation(constellation)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#if(!done):
		#if(stars_ready):
		#	print(stars_ready)
			#render_constellation([])
			#done = true
		#if(constellations_ready and stars_ready):
			#render_constellations()
			#done=true
	pass
