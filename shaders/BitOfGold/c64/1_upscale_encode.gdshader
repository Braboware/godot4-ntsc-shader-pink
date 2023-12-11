shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

// https://www.shadertoy.com/view/3tVBWR

// UPSCALE & ENCODE NTSC

const float XRES = 54.0 * 8.0;
const float YRES = 33.0 * 8.0;

const mat3 yiq_mat = mat3(
    vec3(0.2989, 0.5959, 0.2115),
    vec3(0.5870, -0.2744, -0.5229),
    vec3(0.1140, -0.3216, 0.3114)
);

vec3 rgb2yiq(vec3 col) {
    return yiq_mat * col;
}

void fragment()
{
    vec2 uv = FRAGCOORD.xy / (1.0 / SCREEN_PIXEL_SIZE).xy;
    vec3 color = texture(screen_texture, uv).xyz;

    // ENCODE LUMA, CHROMA SUBCARRIER LEVEL, PHASE

    vec3 signal = rgb2yiq(color);
    vec2 chroma = vec2(signal.y, signal.z);
    float lchroma = length(chroma);
    float phase = atan(signal.y, signal.z);

    float mscanl = mod(uv.y * YRES, 2.0);
    phase += -0.3926991 + mscanl * 0.19634954; // 22.5 degrees phase shift between lines

    vec3 ocolor = vec3(signal.x, lchroma, phase / 6.28318530718);

    COLOR = vec4(ocolor, 1.0);
}