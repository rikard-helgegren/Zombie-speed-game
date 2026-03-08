shader_type canvas_item;

uniform float vision_radius;

//TODO not working, overwritten.
uniform float fog_opacity = 0.2;  // 0 = transparent, 1 = fully opaque
uniform float edge_softness = 50.0;  // How soft the edges are

void fragment() {
    // Get viewport size
    vec2 viewport_size = 1.0 / SCREEN_PIXEL_SIZE;
    // Center of screen
    vec2 screen_center = viewport_size * 0.5;
    // Current fragment position in pixels
    vec2 frag_pos = FRAGCOORD.xy;
    
    // Distance from center
    float dist = distance(frag_pos, screen_center);
    
    // Fade based on distance
    float alpha = smoothstep(vision_radius, vision_radius + edge_softness, dist);
    alpha *= fog_opacity;  // Apply opacity multiplier
    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}