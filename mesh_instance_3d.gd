extends MeshInstance3D

# FastNoiseLite instance
var noise = FastNoiseLite.new()

# Function to generate terrain mesh
func generate_terrain():
	var mesh = ArrayMesh.new()
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var size = 50  # Size of the terrain grid
	var divisions = 10  # Number of subdivisions (affects poly count)
	var scale = 0.1  # Scale for noise frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX  # Use simplex noise

	# Loop to generate vertices
	for x in range(divisions):
		for z in range(divisions):
			var pos = Vector3(x * size / divisions, 0, z * size / divisions)
			
			# Displace y-axis with noise for terrain height variation
			pos.y = noise.get_noise_2d(x * scale, z * scale) * 5  # Multiply to control height
			surface_tool.add_vertex(pos)

			# Add the second triangle of the quad (triangulating each grid quad)
			if x < divisions - 1 and z < divisions - 1:
				var next_x = Vector3((x + 1) * size / divisions, 0, z * size / divisions)
				var next_z = Vector3(x * size / divisions, 0, (z + 1) * size / divisions)
				surface_tool.add_vertex(next_x)
				surface_tool.add_vertex(next_z)

	surface_tool.generate_normals()
	surface_tool.commit(mesh)
	self.mesh = mesh

# Generate terrain when ready
func _ready():
	generate_terrain()
