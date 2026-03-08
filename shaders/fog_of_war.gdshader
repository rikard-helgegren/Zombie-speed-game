shader_type canvas_item;

uniform float vision_radius;

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
    float alpha = smoothstep(vision_radius, vision_radius + 50.0, dist);
    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}