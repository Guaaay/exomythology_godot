shader_type spatial;

// Define the albedo color with a default value (white)
uniform vec4 albedo = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    // Apply the albedo color to the material
    ALBEDO = albedo.rgb;
}
