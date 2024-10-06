extends Node

@onready var httpRequest = $RequestStars
@onready var constLines = %ConstLines
var star_scene = preload("res://star.tscn")
# Define your sphere radius
var radius = 120.0
# Array of star positions and brightness values

var json = JSON.new()

func get_star_dict(json_string):
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
	else:
		print("ERROR")
		return []
	
	var stars_vectors = []
	for estrella in json.data:
		stars_vectors.append(estrella)
	print(stars_vectors)	
	return json.data
	
	#Vector2(float(estrella[0]),float(estrella[1])
func add_stars(stars):
	for star_id in stars.keys():
		var pos = stars[star_id][0]
		
		var brillo = stars[star_id][1]
		var star_mesh = star_scene.instantiate()
		star_mesh.star_id = star_id
		star_mesh.position = pos
		star_mesh.scale *= (0.5 + float(brillo))
		# Add it to the scene tree
		add_child(star_mesh)
		star_mesh.add_to_group("spheres")  # Add the sphere to the "spheres" group
	constLines.stars_ready = true	

# Parameters for the dome (half-sphere)
var dome_center = Vector3(0, 0, 0)  # Center of the sphere (could be at the origin)
var dome_radius = radius

# Function to calculate ray-sphere intersection
func raycast_to_dome(camera_position: Vector3, ray_direction: Vector3):
	# Normalize the ray direction (in case it's not already normalized)
	ray_direction = ray_direction.normalized()
	# Vector from sphere center to camera position
	var L = camera_position - dome_center
	# Calculate the quadratic equation components
	var a = ray_direction.dot(ray_direction)  # a = 1 since ray_direction is normalized
	var b = 2.0 * ray_direction.dot(L)
	var c = L.dot(L) - dome_radius * dome_radius
	# Calculate the discriminant
	var discriminant = b * b - 4 * a * c
	# If the discriminant is negative, there's no intersection
	if discriminant < 0:
		return null  # No intersection
	# Calculate the two possible solutions for t
	var t1 = (-b - sqrt(discriminant)) / (2 * a)
	var t2 = (-b + sqrt(discriminant)) / (2 * a)
	# We want the smallest positive t (the closest intersection point)
	var t = -1
	if t1 > 0 and t2 > 0:
		t = min(t1, t2)
	elif t1 > 0:
		t = t1
	elif t2 > 0:
		t = t2
	# If t is still negative, the intersection is behind the camera
	if t < 0:
		return null  # No valid intersection
	# Calculate the intersection point
	var intersection_point = camera_position + t * ray_direction
	# Ensure the intersection is on the upper hemisphere (y > dome_center.y)
	if intersection_point.y < dome_center.y:
		return null  # Intersection is below the dome (not valid for a half-sphere)
	return intersection_point  # Valid intersection point



# Function to project 2D points to a 3D half-sphere (hemisphere)
func project_to_dome(star_pos: Vector2) -> Vector3:
	# Convert 2D Cartesian coordinates to polar coordinates
	var distance_from_origin = star_pos.length()
	var angle = star_pos.angle()

	# Normalize the distance so it fits within the dome
	# Here we assume the 2D plane's maximum distance from the origin is equal to the radius
	var normalized_distance = distance_from_origin / radius
	
	# Clamp the normalized distance to be within [0, 1] to ensure we stay on the hemisphere
	normalized_distance = clamp(normalized_distance, 0.0, 1.0)
	
	# Compute the 3D position on the hemisphere
	var phi = normalized_distance * PI / 2  # Angle from zenith to horizon (0 to PI/2)
	var x = radius * sin(phi) * cos(angle)  # X position on dome
	var y = radius * cos(phi)               # Y is the height on the dome
	var z = radius * sin(phi) * sin(angle)  # Z position on dome
	
	return Vector3(x, y, z)

func render_stars(json_string):
	var projected_stars = {}
	var stars2_dict = get_star_dict(json_string) # Returns a dictionary dictionary
	for star_id in stars2_dict.keys():
		var star_pos = Vector2(float(stars2_dict[star_id][0]),float(stars2_dict[star_id][1]))
		if(star_pos.length() > radius - 10):
			continue
		projected_stars[star_id]=[project_to_dome(star_pos),stars2_dict[star_id][2]]
		
	add_stars(projected_stars)
	
func _ready():
	httpRequest.request_completed.connect(_on_request_completed)
	httpRequest.timeout = 30  # 30 seconds timeout
	var error = httpRequest.request("https://api.exomythology.earth/api/star_positions/?planet_ra=185.179&planet_dec=17.7933&normalization=%d" % radius)
	print("request sent")
	if error != OK:
		print("Error making request: ", error)
	

func _on_request_completed(result, response_code, headers, body):
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
		render_stars(json_string)
