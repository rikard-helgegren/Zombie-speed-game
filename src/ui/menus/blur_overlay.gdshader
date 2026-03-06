shader_type canvas_item;

uniform float blur_amount: hint_range(0.0, 5.0) = 1.5;
uniform sampler2D screen_texture: hint_screen_texture;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 blur_color = vec4(0.0);
	
	// Apply directional blur by sampling multiple times
	float blur_samples = 16.0;
	for (float i = 0.0; i < blur_samples; i++) {
		float angle = (i / blur_samples) * 6.28318;
		vec2 offset = vec2(cos(angle), sin(angle)) * blur_amount * 0.001;
		blur_color += texture(screen_texture, uv + offset);
	}
	
	blur_color /= blur_samples;
	
	// Apply semi-transparent dark overlay
	vec4 overlay = vec4(0.0, 0.0, 0.0, 0.35); // Your current color
	COLOR = mix(blur_color, overlay, 0.4) + overlay * 0.6;
}
