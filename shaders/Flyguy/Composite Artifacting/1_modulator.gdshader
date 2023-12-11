shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

// https://www.shadertoy.com/view/XtcGDl

#define F_COL (1.0 / 4.0)

const mat3 rgb2yiq = mat3(
    vec3(0.299, 0.596, 0.211),
    vec3(0.587,-0.274,-0.523),
    vec3(0.114,-0.322, 0.312)
);

//Complex oscillator, Fo = Oscillator freq., Fs = Sample freq., n = Sample index
vec2 Oscillator(float Fo, float Fs, float n)
{
    float phase = (TAU * Fo * floor(n)) / Fs;
    return vec2(cos(phase),sin(phase));
}

void fragment()
{
    float Fs = (1.0 / SCREEN_PIXEL_SIZE).x;
    float Fcol = Fs * F_COL;
    float n = floor(FRAGCOORD.x);

    //vec3 cRGB = texture(screen_texture, FRAGCOORD.xy / (1.0 / SCREEN_PIXEL_SIZE).xy).rgb;
    vec3 cRGB = texture(screen_texture, SCREEN_UV).rgb;
    vec3 cYIQ = rgb2yiq * cRGB;

    vec2 cOsc = Oscillator(Fcol, Fs, n);

    float sig = cYIQ.x + dot(cOsc, cYIQ.yz);

    COLOR = vec4(sig,0,0,1.0);
}