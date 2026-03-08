shader_type canvas_item;

uniform vec2 player_position;
uniform float vision_radius;
uniform vec2 screen_size;

void fragment() {
    vec2 screen_pos = UV * screen_size;
    float dist = length(screen_pos - player_position);
    float alpha = smoothstep(vision_radius, vision_radius + 50.0, dist);
    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}