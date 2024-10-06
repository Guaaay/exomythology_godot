class_name TerrainGeneration
extends Node

var mesh : MeshInstance3D
var size_depth: int = 500
var size_width: int = 500
var mesh_resolution: int = 1

@export var noise : FastNoiseLite

# Called when the node enters the scene tree for the first time.
func _ready():
	generate()
	pass # Replace with function body.


func generate():
	noise.seed = Global.exo_id
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(size_width, size_depth)
	plane_mesh.subdivide_depth = size_depth * mesh_resolution
	plane_mesh.subdivide_width = size_width * mesh_resolution
	plane_mesh.material = preload("res://terrain_material.tres")
	var hue = fmod(1+(float(Global.exo_id)/10.0),1.0)
	var new_color = Color.from_hsv(hue, 1, 0.4, 1)
	plane_mesh.material.albedo_color=new_color
	
	var surface = SurfaceTool.new()
	var data = MeshDataTool.new()
	surface.create_from(plane_mesh,0)
	
	var array_plane = surface.commit()
	data.create_from_surface(array_plane, 0)
	
	for i in range(data.get_vertex_count()):
		var vertex = data.get_vertex(i)
		vertex.y = get_noise_y(vertex.x,vertex.z)
		data.set_vertex(i,vertex)
	
	array_plane.clear_surfaces()
	
	data.commit_to_surface(array_plane)
	
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	surface.create_from(array_plane,0)
	surface.generate_normals()
	
	
	
	mesh = MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.create_trimesh_collision()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	
func get_noise_y(x,z) -> float:
	var value = noise.get_noise_2d(x,z)
	return value*15
