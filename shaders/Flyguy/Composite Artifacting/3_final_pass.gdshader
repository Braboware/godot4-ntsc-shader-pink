shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

#define HUE 0.0
#define SATURATION 40.0
#define BRIGHTNESS 1.0

#define COMPOSITE 0 //Composite demodulated image
#define RGB 1 //Raw RGB input image
#define LUMA 2 //Luma component
#define CHROMA 3 //Chroma component
#define SIGNAL 4 //Modulated image
#define SPLIT 5 //Left = Input RGB, Right = Output composite

#define VIEW_MODE COMPOSITE

#define F_COL (1.0 / 4.0)
#define F_LUMA_LP (1.0 / 6.0)

#define FIR_SIZE 29

const mat3 yiq2rgb = mat3(
    vec3(1.000, 1.000, 1.000),
    vec3(0.956,-0.272,-1.106),
    vec3(0.621,-0.647, 1.703)
);

//Angle -> 2D rotation matrix
mat2 rotate(float a)
{
    return mat2(
        vec2(cos(a), sin(a)),
        vec2(-sin(a), cos(a))
    );
}

float sinc(float x)
{
	return (x == 0.0) ? 1.0 : sin(x * PI) / (x * PI);
}

//https://en.wikipedia.org/wiki/Window_function
float WindowBlackman(float a, int N, int i)
{
    float a0 = (1.0 - a) / 2.0;
    float a1 = 0.5;
    float a2 = a / 2.0;

    float wnd = a0;
    wnd -= a1 * cos(2.0 * PI * (float(i) / float(N - 1)));
    wnd += a2 * cos(4.0 * PI * (float(i) / float(N - 1)));

    return wnd;
}

//FIR lowpass filter
//Fc = Cutoff freq., Fs = Sample freq., N = # of taps, i = Tap index
float Lowpass(float Fc, float Fs, int N, int i)
{
    float wc = (Fc/Fs);

    float wnd = WindowBlackman(0.16, N, i);

    return 2.0*wc * wnd * sinc(2.0*wc * float(i - N/2));
}

void fragment()
{
    float Fs = (1.0 / SCREEN_PIXEL_SIZE).x;
    //float Fcol = Fs * F_COL;
    float Flumlp = Fs * F_LUMA_LP;
    //float n = floor(FRAGCOORD.x);

	vec2 uv = FRAGCOORD.xy;

    float luma = texelFetch(screen_texture, ivec2(uv), 0).r;
    vec2 chroma = vec2(0);

    //Filtering out unwanted high freqency content from the chroma(IQ) signal.
    for(int i = 0;i < FIR_SIZE;i++)
    {
        int tpidx = FIR_SIZE - i - 1;
        float lp = Lowpass(Flumlp, Fs, FIR_SIZE, tpidx);
        chroma += texelFetch(screen_texture, ivec2(uv) + ivec2(i - FIR_SIZE/2, 0), 0).yz * lp;
    }

    chroma *= rotate(TAU * HUE);

    vec3 color = yiq2rgb * vec3(BRIGHTNESS * luma, chroma * SATURATION);

    #if(VIEW_MODE == COMPOSITE)
    	COLOR = vec4(color, 1.0);

    #elif(VIEW_MODE == RGB)
   		COLOR = texture(iChannel1, uv / iResolution.xy);

    #elif(VIEW_MODE == LUMA)
    	COLOR = vec4(luma);

    #elif(VIEW_MODE == CHROMA)
    	COLOR = vec4(40.0*chroma+0.5,0,1.0);

    #elif(VIEW_MODE == SIGNAL)
    	COLOR = 0.5 * texture(iChannel2, uv / iResolution.xy).rrrr+0.25;

    #elif(VIEW_MODE == SPLIT)
    	if(uv.x < iResolution.x/2.0)
        {
            fragColor = texture(iChannel1, uv / iResolution.xy);
        }
        else
        {
    		fragColor = vec4(color, 1.0);
        }
    #endif
}