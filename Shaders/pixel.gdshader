shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 32.0) = 4.0;

void fragment() {
    vec2 snapped = floor(FRAGCOORD.xy / pixel_size) * pixel_size + pixel_size * 0.5;
    COLOR = texture(screen_texture, snapped * SCREEN_PIXEL_SIZE);
}