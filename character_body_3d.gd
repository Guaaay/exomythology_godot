extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAX_LENGTH = 200
const SCALE = 3

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var neck := get_node("Neck")
@onready var camera := get_node("Neck/Camera3D")
@onready var line = preload("res://const_line.tscn")
@onready var crosshair_select = load("res://const.png")
@onready var crosshair_select_normal = load("res://const_normal.png")
@onready var crosshair_select_good = load("res://const_good.png")
@onready var crosshair_normal = load("res://crosshair.png")
@onready var raycast := %RayCast3D
@onready var crosshair := %Crosshair
@onready var constLines := %ConstLines
@onready var star_renderer = %StarRenderer

var drawing = false
var mouse_pressed = false
var hovering = false
var check = false

var origin_star = null
var current_line = null

var different = false

var last_mesh: MeshInstance3D = null
var last_sphere = null
var original_scale: Vector3 = Vector3.ONE
var current_pointer_pos = Vector3(0,0,0)
var current_constellation = []

func _ready():
	var screen_size = get_viewport().get_visible_rect().size
	crosshair.position = screen_size / 2

func generate_line():
	current_line = line.instantiate()
	scale_line(last_sphere.position, current_pointer_pos)
	current_line.scale.x *= 1
	current_line.scale.z *= 1
	constLines.add_child(current_line)
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventKey and event.pressed:
			# Check if the Enter key or Return key is pressed
			if(event.is_action_pressed("Enter")):
				if(current_constellation.size() > 0):
					var json = JSON.new()
					var message = json.stringify(current_constellation)
					JavaScriptBridge.eval("window.parent.postMessage('" + message + "', '*')", true)
				
		elif event is InputEventMouseButton:
			if(event.button_index == 1 and event.pressed and hovering and !drawing):
				mouse_pressed = true
				crosshair.scale = Vector2(0.08,0.08)
				crosshair.set_texture(crosshair_select)
				origin_star = last_sphere
				generate_line()
				drawing = true
			elif(event.button_index == 1 and !event.pressed and hovering and different):
				if(drawing):
					var first_sphere = last_sphere
					drawing = false 
					check = true
					check_looked_at_sphere()
					check = false
					var current_sphere = last_sphere
					scale_line(first_sphere.position,current_sphere.position)
					current_constellation.append([first_sphere.star_id,current_sphere.star_id])
					print(current_constellation)
				crosshair.set_texture(crosshair_select_normal)
				mouse_pressed = false
				drawing = false
			else:
				if(drawing):
					delete_current_line()
				drawing = false
				mouse_pressed = false
				crosshair.scale = Vector2(0.02,0.02)
				crosshair.set_texture(crosshair_normal)
				
		elif event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.005)
			camera.rotate_x(-event.relative.y * 0.005)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(0), deg_to_rad(85))
			check_looked_at_sphere()
			var raycast_global_direction = raycast.global_transform.basis * raycast.target_position + Vector3(0,20,0)
			current_pointer_pos = star_renderer.raycast_to_dome(camera.position, raycast_global_direction)
			if(drawing):
				scale_line(last_sphere.position, current_pointer_pos)

func delete_current_line():
	constLines.remove_child(current_line)

func _physics_process(delta: float) -> void:
	#print(drawing)
	# Add the gravity.
	#if not is_on_floor():
	#	velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()
		# Perform the raycast check to detect the sphere the player is looking at.
	
func scale_line(point1: Vector3, point2: Vector3):
	if current_line == null:
		return

	var dir = point2 - point1
	var length = dir.length()
	if(length > MAX_LENGTH):
		drawing = false
		mouse_pressed = false
		crosshair.scale = Vector2(0.02,0.02)
		crosshair.set_texture(crosshair_normal)
		delete_current_line()
		return
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



func check_looked_at_sphere() -> void:
	# Perform the raycast.
	if raycast.is_colliding():
		var collided_object = raycast.get_collider()
		# Check if the collided object is a sphere (or has a specific group, like "spheres").
		if collided_object != null:
			var mesh = collided_object.get_node("MeshInstance3D")
			different = (mesh != last_sphere)
			# If looking at a new sphere, scale it up.
			if mesh != last_mesh:
				# Reset the scale of the previously looked-at sphere.
				if last_mesh != null:
					last_mesh.scale = original_scale
				
				# Store the new sphere and its original scale
				if(!drawing):
					last_sphere = collided_object as Node3D
				last_mesh = mesh as Node3D
				original_scale = last_mesh.scale
				crosshair.scale = Vector2(0.08,0.08)
				if(!mouse_pressed):
					crosshair.set_texture(crosshair_select_normal)
				elif(different):
					crosshair.set_texture(crosshair_select_good)
				hovering = true
				# Scale up the new sphere.
				last_mesh.scale = Vector3(SCALE,SCALE,SCALE)
			elif(check):
				last_sphere = collided_object as Node3D
			
		else:
			
			# If not looking at a sphere, reset the scale of the last looked-at sphere.
			hovering = false
			if last_mesh != null:
				last_mesh.scale = original_scale
				last_mesh = null
	else:
		if(!mouse_pressed):
			hovering = false
			crosshair.scale = Vector2(0.02,0.02)
			crosshair.set_texture(crosshair_normal)
		else:
			hovering = false
			crosshair.set_texture(crosshair_select)
		# Reset the scale if not looking at any object.
		if last_mesh != null:
			last_mesh.scale = original_scale
			last_mesh = null
