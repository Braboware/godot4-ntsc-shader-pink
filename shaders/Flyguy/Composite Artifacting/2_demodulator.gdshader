shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

#define F_COL (1.0 / 4.0)
#define F_LUMA_LP (1.0 / 6.0)
#define F_COL_BW (1.0 / 50.0)

#define FIR_SIZE 29

//Complex multiply
vec2 cmul(vec2 a, vec2 b)
{
   return vec2((a.x * b.x) - (a.y * b.y), (a.x * b.y) + (a.y * b.x));
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

//FIR bandpass filter
//Fa/Fb = Low/High cutoff freq., Fs = Sample freq., N = # of taps, i = Tap index
float Bandpass(float Fa, float Fb, float Fs, int N, int i)
{
    float wa = (Fa/Fs);
    float wb = (Fb/Fs);

    float wnd = WindowBlackman(0.16, N, i);

    return 2.0*(wb-wa) * wnd * (sinc(2.0*wb * float(i - N/2)) - sinc(2.0*wa * float(i - N/2)));
}

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
    float Fcolbw = Fs * F_COL_BW;
    float Flumlp = Fs * F_LUMA_LP;
    float n = floor(FRAGCOORD.x);

    float y_sig = 0.0;
    float iq_sig = 0.0;

    vec2 cOsc = Oscillator(Fcol, Fs, n);

    n += float(FIR_SIZE)/2.0;

    //Separate luma(Y) & chroma(IQ) signals
    for(int i = 0;i < FIR_SIZE;i++)
    {
        int tpidx = FIR_SIZE - i - 1;
        float lp = Lowpass(Flumlp, Fs, FIR_SIZE, tpidx);
        float bp = Bandpass(Fcol - Fcolbw, Fcol + Fcolbw, Fs, FIR_SIZE, tpidx);

        y_sig += texelFetch(screen_texture, ivec2(int(n - float(i)), int(FRAGCOORD.y)), 0).r * lp;
        iq_sig += texelFetch(screen_texture, ivec2(int(n - float(i)), int(FRAGCOORD.y)), 0).r * bp;
    }

    //Shift IQ signal down from Fcol to DC
    vec2 iq_sig_mix = cmul(vec2(iq_sig, 0), cOsc);

    COLOR = vec4(y_sig, iq_sig_mix, 1.0);
}