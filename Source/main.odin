package clap_ambient

import "base:runtime"
import intrin "base:intrinsics"
import "core:math"
import "core:sys/windows"
import "core:mem"
import vmem "core:mem/virtual"
import "core:slice"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "vendor:directx/d3d11"
import "vendor:directx/dxgi"

import imgui "../odin-imgui"
import "../odin-imgui/imgui_impl_win32"
import "../odin-imgui/imgui_impl_dx11"
import clap  "../clap-odin"
import clap_ext "../clap-odin/ext"

// une interface avec des nodes qui représentent les effets -> github.com/Nelarius/imnodes
// on peut drag les effets dans 3 ou 4 colonnes pour donner l'ordre (on peut mettre en parallele)
// chaque node peut etre configuré sur n'importe quel effet et l'interface s'affiche dans le node
// effets : delay, delay multitap, granulaire temps réel, reverb(s), looper habit chelou ?
// pourquoi pas dans le fond afficher le spectre de sortie ou une animation rigolote (apprendre opengl imagine)


ParamIDs :: enum {

    //Global 
    InGain,
    OutGain,
    
    // echo 
    EchoTime,
    EchoFeedback,
    EchoTone,
    EchoModFreq,
    EchoModAmount,
    EchoMix,
    
    //reverb
    ReverbDecay,
    ReverbSize,
    ReverbEarlyDiffusion,
    ReverbLateDiffusion,
    ReverbTone,
    ReverbMix,
}

ParamInfo :: struct {
    name: string,
    min: f32,
    max: f32,
    default_value: f32,
    imgui_flags: u32,
    clap_param_flags: clap_ext.Param_Info_Flag,
}

@(rodata)
parameter_infos := [ParamIDs]ParamInfo {
    .InGain = {
        name = "Input Gain (dB)", min = -60.0, max = 6.0, default_value = 0.0,
        imgui_flags = 0,
        clap_param_flags = .AUTOMATABLE,
    },
    .OutGain = {
        name = "Output Gain (dB)", min = -60.0, max = 6.0, default_value = 0.0,
        imgui_flags = 0,
        clap_param_flags = .AUTOMATABLE,
    },

    .EchoTime = {
        name = "Delay Time", min = 1.0, max = 2000.0, default_value = 300.0,
        imgui_flags = 0,
        clap_param_flags = .AUTOMATABLE
    },
    .EchoFeedback = {
        name = "Feedback", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = 0,
        clap_param_flags = .AUTOMATABLE
    },
    .EchoTone = {
        name = "Echo tone", min = 0.0, max = 20000.0, default_value = 20000.0,
        imgui_flags = 0, // @TODO logarithmic
        clap_param_flags = .AUTOMATABLE,
    },
    .EchoModFreq = {
        name = "Echo mod freq", min = 0.0, max = 10.0, default_value = 1.0,
        imgui_flags = 0,
        clap_param_flags = .AUTOMATABLE,
    },
    .EchoModAmount = {
        name = "Echo mod amount", min = 0.0, max = 1.0, default_value = 0.0,
        imgui_flags = 0,
        clap_param_flags = .AUTOMATABLE,
    },
    .EchoMix = {
        name = "Mix", min = 0.0, max = 1.0, default_value = 0.0,
        imgui_flags = 0,
        clap_param_flags = .AUTOMATABLE
    },

    .ReverbDecay = {
        name = "Reverb decay", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = 0,
        clap_param_flags = .AUTOMATABLE,     
    },
    .ReverbSize = {
        name = "Reverb size", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = 0,
        clap_param_flags = .AUTOMATABLE,
    },
    .ReverbEarlyDiffusion = {},
    .ReverbLateDiffusion = {},
    .ReverbTone = {
        name = "Reverb Tone", min = 0.0, max = 1.0, default_value = 1.0,
        imgui_flags = 0,
        clap_param_flags = .AUTOMATABLE,
    },
    .ReverbMix = {
        name = "Reverb mix", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = 0,
        clap_param_flags = .AUTOMATABLE,
    },
}

PIf32 :: f32(math.PI)
PI_4f32 :: f32(math.PI / 4)

dbtoa :: #force_inline proc(x: f32) -> f32 { return math.pow(10.0, x * 0.05) }
atodb :: #force_inline proc(x: f32) -> f32 { return 20.0 * math.log10(x) }

ms_to_samples_frac :: #force_inline proc(x, samplerate: f32) -> f32 { return x * 0.001*samplerate }
ms_to_samples :: #force_inline proc(x, samplerate: f32) -> int { return int(x * 0.001*samplerate) }

lagrange3_interp :: #force_inline proc(y0, y1, y2, y3: f32, t: f32) -> f32 {    
    t1 := t - 1.0
    t2 := t - 2.0
    t3 := t - 3.0
    
    return -y0 * (t1*t2*t3)/6.0 + t*(y1 * t2*t3*0.5 - y2 * t1*t3*0.5 + y3 * t1*t2/6.0)
}


RampedValue :: struct {
    target: f32,
    current_value: f32,
    step_height: f32,
    value_buffer: []f32,
}

ramped_value_init :: proc(value: ^RampedValue, init_value: f32, buffer_size: u32, allocator: runtime.Allocator) {
    value.target = init_value
    value.step_height = 0.0
    value.current_value = init_value
    value.value_buffer = make([]f32, buffer_size, allocator)
}

RAMP_TIME_MS : f32 : 100.0

ramped_value_new_target :: proc (value: ^RampedValue, new_target: f32, samplerate: f32) {
    value.target = new_target
    value.step_height = abs(value.current_value - new_target)/(RAMP_TIME_MS * 0.001 * samplerate)
}

ramped_value_step :: #force_inline proc(value: ^RampedValue) -> f32 {
    
    if value.target == value.current_value {
        return value.current_value
    }

    distance := value.target - value.current_value
    
    if value.step_height >= abs(distance) {
        value.current_value = value.target
        return value.current_value
    }
    value.current_value += math.sign(distance)*value.step_height
    return value.current_value
}

ramped_value_fill_buffer :: proc(value: ^RampedValue, nsamples: u32) {
    
    for index in 0..<nsamples {
        value.value_buffer[index] = ramped_value_step(value)
    }
}


ParamEventType :: enum {
    GUI_VALUE_CHANGE,
    GUI_GESTURE_BEGIN,
    GUI_GESTURE_END,
}

ParamEvent :: struct {
    param_index: ParamIDs,
    event_type: ParamEventType,
    value: f32,
}

FIFO_SIZE :: 256
EventFIFO :: struct {
    events: [FIFO_SIZE]ParamEvent,
    write_index: u32,
    read_index: u32
}

main_push_event_to_audio :: proc(plugin: ^PluginData, param_index: ParamIDs, event_type: ParamEventType, value: f32) {

    write_index := intrin.atomic_load(&plugin.main_to_audio_fifo.write_index)
    
    event: ^ParamEvent = &plugin.main_to_audio_fifo.events[write_index]
    event.param_index = param_index
    event.event_type = event_type
    event.value = value
    
    intrin.atomic_add(&plugin.main_to_audio_fifo.write_index, 1)
    intrin.atomic_and(&plugin.main_to_audio_fifo.write_index, FIFO_SIZE-1)
}

DelayLine :: struct {
    buffer: []f32,
    write_index: u32,
}

delay_line_push_sample :: #force_inline proc(dl: ^DelayLine, sample: f32) {
    dl.buffer[dl.write_index] = sample
    dl.write_index += 1
    if int(dl.write_index) >= len(dl.buffer) { dl.write_index = 0}
}

delay_line_read_sample_lagrange :: #force_inline proc(dl: DelayLine, read_position: f32) -> f32  {    
    read_position := read_position
    
    if read_position < 0.0 { read_position += f32(len(dl.buffer)) }
    if read_position >= f32(len(dl.buffer)) { read_position -= f32(len(dl.buffer)) }
        
    assert(read_position >= 0.0)
    assert(read_position < f32(len(dl.buffer)))
    
    index1 := int(read_position)
    index2 := index1 +1
    index3 := index2 +1
    index4 := index3 +1
    
    if index4 >= len(dl.buffer) {
        index1 %= len(dl.buffer)
        index2 %= len(dl.buffer)
        index3 %= len(dl.buffer)
        index4 %= len(dl.buffer)
    }
    
    sample1 := dl.buffer[index1]
    sample2 := dl.buffer[index2]
    sample3 := dl.buffer[index3]
    sample4 := dl.buffer[index4]
    
    interp := read_position - f32(index1)    
    out_sample := lagrange3_interp(sample1, sample2, sample3, sample4, interp)
    
    return out_sample
}

delay_line_read_sample_linear :: proc(dl: DelayLine, read_position: f32) -> f32 {
    read_position := read_position
    
    if read_position < 0.0 { read_position += f32(len(dl.buffer)) }
    if read_position >= f32(len(dl.buffer)) { read_position -= f32(len(dl.buffer)) }
    
    read_index1 := int(read_position)
    read_index2 := read_index1 + 1
    
    if read_index2 >= len(dl.buffer) { read_index2 -= len(dl.buffer) }
    
    interp_coeff := read_position - f32(read_index1)
    sample1 := dl.buffer[read_index1]
    sample2 := dl.buffer[read_index2]
    
    output_sample := math.lerp(sample1, sample2, interp_coeff)
    return output_sample
}


Reverb :: struct {
    // faire 4 allpass et un FDN4 pour commencer
    // @TODO tester la chaine de allpass (prendre les valeurs de la progenitor)
    // APRES, commencer à construire un FDN4 PUIS un FDN16
    // expérimenter avec différentes formes de allpass (ordre 2, multitap...)
    
    early: struct {
        allpasses: [4]AllpassDelay,
    },
    
    late: struct {
        delay_lines: [4]DelayLine,
        delay_frac: [4]f32,
        lp_filters: [4]Biquad,
        feedback: f32,
    },
    
    input_buffer: []f32,    
    mix: f32,
}


reverb_process :: proc(reverb: ^Reverb, bufferL: []f32, bufferR: []f32) {
    
    //early stages
    nsamples := len(bufferL)
    
    for index in 0..<nsamples {
        reverb.input_buffer[index] = (bufferL[index] + bufferR[index])*0.5
    }

    
    for allpass_index in 0..<len(reverb.early.allpasses) {
        allpass_process_buffer(&reverb.early.allpasses[allpass_index], reverb.input_buffer)
    }
    
    { //late  
    // screams SIMD    
        fdn_order : int : 4
        mixing_matrix := [4][4]f32 { {1,  1,  1,  1},
                                     {1, -1,  1, -1},
                                     {1,  1, -1, -1},
                                     {1, -1, -1,  1}, }
    
        for index in 0..<nsamples{
            delay_outputs: [fdn_order]f32
            mixing_outputs: [fdn_order]f32
            
            fdn_in_sample := reverb.input_buffer[index]
            
            for channel in 0..<fdn_order {
                read_index_frac := f32(reverb.late.delay_lines[channel].write_index) - reverb.late.delay_frac[channel]
                delay_outputs[channel] = delay_line_read_sample_lagrange(reverb.late.delay_lines[channel], 
                                                                         read_index_frac)
            }
            
            bufferL[index] = math.lerp(bufferL[index], delay_outputs[2], reverb.mix)
            bufferR[index] = math.lerp(bufferR[index], delay_outputs[3], reverb.mix)
                        
            for channel in 0..<fdn_order {
                for matrix_index in 0..<fdn_order {
                    mixing_outputs[channel] += delay_outputs[channel]*mixing_matrix[channel][matrix_index]
                }
                mixing_outputs[channel] *= 0.5
            }            
            
            for channel in 0..<fdn_order {
                delay_in := biquad_process_sampleL(&reverb.late.lp_filters[channel], 
                                                                 mixing_outputs[channel])
            
                delay_line_push_sample(&reverb.late.delay_lines[channel], 
                                       delay_in * reverb.late.feedback + fdn_in_sample)
            }
        }
    }    
}

ProgenitorReverb :: struct {}


Echo :: struct {
    delay_lineL: DelayLine,
    delay_lineR: DelayLine,
    delay_frac: RampedValue,
    feedback: RampedValue,
    mix: RampedValue,
    tone_filter: Biquad,
    lfo: LFO,
    mod_amount: f32
}

echo_process :: proc(echo: ^Echo, bufferL: []f32, bufferR: []f32) {
        
    nsamples := u32(len(bufferL))
    
    lfo_fill_buffers(&echo.lfo, nsamples)
    ramped_value_fill_buffer(&echo.delay_frac, nsamples)    
    ramped_value_fill_buffer(&echo.feedback, nsamples)
    ramped_value_fill_buffer(&echo.mix, nsamples)
        
    for index in 0..<nsamples {
        
        mod_value := f64(echo.lfo.sin_buffer[index] * echo.mod_amount)
        read_index_frac := f64(echo.delay_lineL.write_index) - f64(echo.delay_frac.value_buffer[index]) + mod_value
        
        in_sampleL := bufferL[index]
        in_sampleR := bufferR[index]
        
        output_sampleL := delay_line_read_sample_lagrange(echo.delay_lineL, f32(read_index_frac))
        output_sampleR := delay_line_read_sample_lagrange(echo.delay_lineR, f32(read_index_frac))
            
        bufferL[index] = math.lerp(in_sampleL, output_sampleL, echo.mix.value_buffer[index])
        bufferR[index] = math.lerp(in_sampleR, output_sampleR, echo.mix.value_buffer[index])
        
        feedback_sampleL := in_sampleL + output_sampleL * echo.feedback.value_buffer[index]
        feedback_sampleR := in_sampleR + output_sampleR * echo.feedback.value_buffer[index]
    
        feedback_sampleL = biquad_process_sampleL(&echo.tone_filter, feedback_sampleL)
        feedback_sampleR = biquad_process_sampleL(&echo.tone_filter, feedback_sampleR)
    
        delay_line_push_sample(&echo.delay_lineL, feedback_sampleL)
        delay_line_push_sample(&echo.delay_lineR, feedback_sampleR)
    }
}


MultiTapEcho :: struct {}

LFO :: struct {
    cos_value: f32,
    sin_value: f32,
    param: f32,
    cos_buffer: []f32,
    sin_buffer: []f32,
}

lfo_init :: proc(lfo: ^LFO, freq: f32, samplerate: f32, buffer_size: u32, allocator: runtime.Allocator) {

    lfo.cos_value = 0.5
    
    lfo.cos_buffer = make([]f32, buffer_size, allocator)
    lfo.sin_buffer = make([]f32, buffer_size, allocator)

    lfo_set_frequency(lfo, freq, samplerate)
}

lfo_set_frequency :: #force_inline proc (lfo: ^LFO, freq: f32, samplerate: f32) {
    lfo.param = 2.0 * math.sin(PIf32 * freq/samplerate)
}

lfo_fill_buffers :: proc(lfo: ^LFO, nsamples: u32) {
    for index in 0..<nsamples {
        lfo_step(lfo, index)
    }
}

lfo_step :: #force_inline proc(lfo: ^LFO, index: u32) {
    lfo.cos_value -= lfo.param * lfo.sin_value
    lfo.sin_value += lfo.param * lfo.cos_value
    
    lfo.cos_buffer[index] = lfo.cos_value
    lfo.sin_buffer[index] = lfo.sin_value
}

Biquad :: struct {
    b0, b1, b2: f32,
    a1, a2: f32, 
    gain: f32,
    w1L, w2L: f32,
    w1R, w2R: f32,
}

biquad_reset :: proc(f: ^Biquad) {
    f.w1L = 0.0
    f.w2L = 0.0
    f.w1R = 0.0
    f.w2R = 0.0
}

make_lowpass1 :: proc(f: ^Biquad, freq: f32, samplerate: f32) {
    K := math.tan(f32(math.PI) * freq/samplerate)
    
    inv_a0 := 1.0/(K+1)
    
    f.b0 = K * inv_a0
    f.b1 = f.b0
    f.b2 = 0.0
    f.a1 = -(K-1.0) * inv_a0
    f.a2 = 0.0
    f.gain = 1.0
}

make_highpass1 :: proc(f: ^Biquad, freq: f32, samplerate: f32) {
    K := math.tan(f32(math.PI) * freq/samplerate)
    
    inv_a0 := 1.0/(K+1)
    
    f.b0 = inv_a0
    f.b1 = -f.b0
    f.b2 = 0.0
    f.a1 = -(K-1.0) * inv_a0
    f.a2 = 0.0
    f.gain = 1.0
}

make_lowshelf1 :: proc(f: ^Biquad, freq: f32, gain_db: f32, samplerate: f32) {
    f.gain = dbtoa(gain_db)
    gainLinear := dbtoa(-gain_db)
    
    freqRadian := freq / samplerate * PIf32

    eta := (gainLinear + 1.0)/(gainLinear - 1.0)
    rho := math.sin(PIf32 * freqRadian * 0.5 - PI_4f32) / math.sin(PIf32 * freqRadian * 0.5 + PI_4f32)

    etaSign : f32 = eta > 0.0 ? 1.0 : -1.0
    alpha1 := gainLinear == 1.0 ? 0.0 : eta - etaSign*math.sqrt(eta*eta - 1.0)

    beta0 := ((1 + gainLinear) + (1 - gainLinear) * alpha1) * 0.5
    beta1 := ((1 - gainLinear) + (1 + gainLinear) * alpha1) * 0.5

    f.b0 = (beta0 + rho * beta1)/(1 + rho * alpha1)
    f.b1 = (beta1 + rho * beta0)/(1 + rho * alpha1)
    f.b2 = 0.0
    f.a1 = -(rho + alpha1)/(1 + rho * alpha1)
    f.a2 = 0.0
}

make_highshelf1 :: proc(f: ^Biquad, freq: f32, gain_db: f32, samplerate: f32) {
    f.gain = 1.0
    gainLinear := dbtoa(gain_db)

    freqRadian := freq / samplerate * PIf32

    eta := (gainLinear + 1.0)/(gainLinear - 1.0)
    rho := math.sin(PIf32 * freqRadian * 0.5 - PI_4f32) / math.sin(PIf32 * freqRadian * 0.5 + PI_4f32)

    etaSign : f32 = eta > 0.0 ? 1.0 : -1.0
    alpha1 := gainLinear == 1.0 ? 0.0 : eta - etaSign*math.sqrt(eta*eta - 1.0)

    beta0 := ((1 + gainLinear) + (1 - gainLinear) * alpha1) * 0.5
    beta1 := ((1 - gainLinear) + (1 + gainLinear) * alpha1) * 0.5

    f.b0 = (beta0 + rho * beta1)/(1 + rho * alpha1)
    f.b1 = (beta1 + rho * beta0)/(1 + rho * alpha1)
    f.b2 = 0.0
    f.a1 = -(rho + alpha1)/(1 + rho * alpha1)
    f.a2 = 0.0
}

make_lowpass2 :: proc(f: ^Biquad, freq: f32, Q: f32, samplerate: f32) {
    w0 := 2 * PIf32 / samplerate * freq
    cosw0 := math.cos(w0)
    sinw0 := math.sin(w0)

    alpha := sinw0/(2.0*Q)

    a0inv := 1.0/(1.0 + alpha)

    f.b0 = (1.0 - cosw0) * 0.5 * a0inv
    f.b1 = 2.0 * f.b0
    f.b2 = f.b0
    f.a1 = 2.0 * cosw0 * a0inv
    f.a2 = -(1.0 - alpha) * a0inv
}

make_highpass2 :: proc(f: ^Biquad, freq: f32, Q: f32, samplerate: f32) {

    w0 := 2 * PIf32 / samplerate * freq
    cosw0 := math.cos(w0)
    sinw0 := math.sin(w0)

    alpha := sinw0/(2.0*Q)

    a0inv := 1.0/(1.0 + alpha)
    
    f.b0 = (1.0 + cosw0) * 0.5 * a0inv
    f.b1 = -2.0 * f.b0
    f.b2 = f.b0
    f.a1 = 2.0 * cosw0 * a0inv
    f.a2 = -(1.0 - alpha) * a0inv
}

make_lowshelf2 :: proc(f: ^Biquad, freq: f32, Q: f32, gain_dB: f32, samplerate: f32) {

    w0 := 2 * PIf32 / samplerate * freq
    cosw0 := math.cos(w0)
    sinw0 := math.sin(w0)

    A := math.pow(f32(10.0), gain_dB/40.0)
    beta := math.sqrt(A)/Q
    a0inv := 1/((A+1) + (A-1)*cosw0 + beta*sinw0)

    f.b0 = (A*((A+1) - (A-1)*cosw0 + beta*sinw0)) * a0inv
    f.b1 = (2*A*((A-1) - (A+1)*cosw0)) * a0inv
    f.b2 = (A*((A+1) - (A-1)*cosw0 - beta*sinw0)) * a0inv
    f.a1 = -(-2*((A-1) + (A+1)*cosw0)) * a0inv
    f.a2 = -((A+1) + (A-1)*cosw0 - beta*sinw0) * a0inv
}

make_highshelf2 :: proc(f: ^Biquad, freq: f32, Q: f32, gain_dB: f32, samplerate: f32) {
    w0 := 2 * PIf32 / samplerate * freq
    cosw0 := math.cos(w0)
    sinw0 := math.sin(w0)

    A := math.pow(f32(10.0), gain_dB/40.0)
    beta := math.sqrt(A)/Q
    a0inv := 1/((A+1) + (A-1)*cosw0 + beta*sinw0)
    

    f.b0 = (A*((A+1) + (A-1)*cosw0 + beta*sinw0)) * a0inv
    f.b1 = (-2*A*((A-1) + (A+1)*cosw0)) * a0inv
    f.b2 = (A*((A+1) + (A-1)*cosw0 - beta*sinw0)) * a0inv
    f.a1 = -(2*((A-1) - (A+1)*cosw0)) * a0inv
    f.a2 = -((A+1) - (A-1)*cosw0 - beta*sinw0) * a0inv
}

make_peak :: proc(f: ^Biquad, freq: f32, Q: f32, gain_dB: f32, samplerate: f32) {
    w0 := 2 * PIf32 / samplerate * freq
    cosw0 := math.cos(w0)
    sinw0 := math.sin(w0)

    A := math.pow(f32(10.0), gain_dB/40.0)
    beta := math.sqrt(A)/Q
    alpha := sinw0 / (2.0 * Q)
    a0inv := 1/(1 + alpha/A)

    f.b0 = (1.0 + alpha * A) * a0inv
    f.b1 = -2.0 * cosw0 * a0inv
    f.b2 = (1.0 - alpha * A) * a0inv
    f.a1 = -f.b1
    f.a2 = -(1.0 - alpha / A) * a0inv
}

biquad_process_sampleL :: #force_inline proc(f: ^Biquad, sample: f32) -> f32 {
    w := sample + f.a1*f.w1L + f.a2*f.w2L
    out_sample := f.b0*w + f.b1*f.w1L + f.b2*f.w2L
    
    f.w2L = f.w1L
    f.w1L = w
    return out_sample
}

biquad_process_sampleR :: #force_inline proc(f: ^Biquad, sample: f32) -> f32 {    
    w := sample + f.a1*f.w1R + f.a2*f.w2R
    out_sample := f.b0*w + f.b1*f.w1R + f.b2*f.w2R
    
    f.w2R = f.w1R
    f.w1R = w
    return out_sample
}

biquad_process :: proc(f: ^Biquad, bufferL: []f32, bufferR: []f32) {

    assert(bufferL != nil)
    
    for index in 0..<len(bufferL) {
        bufferL[index] = biquad_process_sampleL(f, bufferL[index])
    }
    
    if bufferR != nil {
        for index in 0..<len(bufferR) {
            bufferR[index] = biquad_process_sampleR(f, bufferR[index])
        }
    }
}

AllpassDelay :: struct {
    delay_line: DelayLine,
    gain: f32,
    delay_frac: f32
}

allpass_process_buffer :: proc(ap: ^AllpassDelay, buffer: []f32) {
    
    for index in 0..<len(buffer) {
        buffer[index] = allpass_process_sample(ap, buffer[index])
    }
}

allpass_process_sample :: #force_inline proc(ap: ^AllpassDelay, in_sample: f32) -> f32 {
        
    // lire le buffer
    // output = delay_sample - input*gain
    // ecrire input + delay_sample*gain dans le buffer
    
    read_position := f32(ap.delay_line.write_index) - ap.delay_frac
    
    delay_sample := delay_line_read_sample_lagrange(ap.delay_line, read_position)
    out_sample := delay_sample - in_sample*ap.gain
    
    feedback_sample := in_sample + delay_sample * ap.gain
    delay_line_push_sample(&ap.delay_line, feedback_sample)
    
    return out_sample
}

AllpassDelayOrder2 :: struct {
    delay_line1: DelayLine,
    delay_line2: DelayLine,
    gain1, gain2: f32,
    delay_frac1, delay_frac2: f32
}

allpass2_process_buffer :: proc() {}
allpass2_process_sample :: #force_inline proc() {}


FDN16 :: struct {}
FDN4 :: struct {}
Looper :: struct {}

GranularDelay :: struct {}

GUI :: struct {}

PluginData :: struct {
    plugin: clap.Plugin,
    host: ^clap.Host,
    host_params: ^clap_ext.Host_Params,

    max_buffer_size: u32,
    min_buffer_size: u32,
    samplerate: f32,

    main_param_values: [ParamIDs]f32,
    audio_param_values: [ParamIDs]f32,
    
    main_to_audio_fifo: EventFIFO,

    main_arena: vmem.Arena,
    echo_arena: vmem.Arena,
    echo: Echo,
    
    reverb_arena: vmem.Arena,
    reverb: Reverb,
    gui: GUI,
}


get_audio_ports_count :: proc "c" (plugin: ^clap.Plugin, is_input: bool) -> u32 { return 1 }

get_audio_ports_info :: proc "c" (plugin: ^clap.Plugin, index: u32, is_input: bool, info: ^clap_ext.Audio_Port_Info) -> bool {
    // si y'a un probleme de canal audio faut revenir ici
    info.id = 0
    info.channel_count = 2
    info.flags = cast(u32)clap_ext.Audio_Port_Flag.IS_MAIN
    info.port_type = clap_ext.AUDIO_PORT_STEREO
    info.in_place_pair = clap.INVALID_ID
    port_name := "Main audio port"
    for charac, index in transmute([]u8)port_name {
       info.name[index] = charac
    }
    return true
}

@(rodata)
audio_port_extension := clap_ext.Plugin_Audio_Ports {
    count = get_audio_ports_count,
    get = get_audio_ports_info,
}

get_num_params :: proc "c" (plugin: ^clap.Plugin) -> u32 { return len(ParamIDs) }

params_get_info :: proc "c" (plugin: ^clap.Plugin, param_index: u32, information: ^clap_ext.Param_Info) -> bool {
    if param_index >= len(ParamIDs) { return false }
    
    param_id := cast(ParamIDs)param_index
    
    mem.zero(information, size_of(information^))
    information.id = param_index
    information.flags = parameter_infos[param_id].clap_param_flags
    information.min_value = f64(parameter_infos[param_id].min)
    information.max_value = f64(parameter_infos[param_id].max)
    information.default_value = f64(parameter_infos[param_id].default_value)
    
    name := parameter_infos[param_id].name
    for char_index in 0..<len(name) {
        information.name[char_index] = raw_data(name)[char_index]
    }
    
    return true
}

param_get_value :: proc "c" (_plugin: ^clap.Plugin, param_id: clap.Clap_Id, out_value: ^f64) -> bool {
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    if param_id > len(ParamIDs) { return false }

    param_index := cast(ParamIDs)param_id
    
    out_value^ = cast(f64)plugin.audio_param_values[param_index]
    return true
}

param_convert_value_to_text :: proc "c" (plugin: ^clap.Plugin, param_id: clap.Clap_Id, value: f64, out_buffer: [^]u8, out_buffer_capacity: u32) -> bool {
    context = runtime.default_context()

    param_index := cast(ParamIDs)param_id

    out_string := strings.string_from_ptr(out_buffer, int(out_buffer_capacity))
    format_string: string
    
    switch param_index {
        case .InGain, .OutGain:     { format_string = "%.2f dB" }
        case .EchoTime:             { format_string = "%.2f ms" }
        case .EchoFeedback:         { format_string = "%.2f" }
        case .EchoTone:             { format_string = "%.2f Hz" }
        case .EchoModFreq:          { format_string = "%.2f Hz" }
        case .EchoModAmount:        { format_string = "%.2f" }
        case .EchoMix:              { format_string = "%.2f" }
        
        case .ReverbDecay:          { format_string = "%.2f" }
        case .ReverbSize:           { format_string = "%.2f" }
        case .ReverbEarlyDiffusion: { format_string = "%.2f" }
        case .ReverbLateDiffusion:  { format_string = "%.2f" }
        case .ReverbTone:           { format_string = "%.2f" }
        case .ReverbMix:            { format_string = "%.2f" }
        case: { return false }
    }
    fmt.bprintf(transmute([]u8)out_string, format_string, value)

    return true
}

param_convert_text_to_value :: proc "c" (plugin: ^clap.Plugin, param_id: clap.Clap_Id, param_value_text: cstring, out_value: ^f64) -> bool {
    context = runtime.default_context()

    in_string := string(param_value_text)
    out_value^ = strconv.atof(in_string)
    return false 
}

param_flush :: proc "c" (_plugin: ^clap.Plugin, in_events: ^clap.Input_Events, out_events: ^clap.Output_Events) {
    context = runtime.default_context()
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    event_count := in_events.size(in_events)
    
    sync_params_main_to_audio(plugin, out_events)

    for event_index in 0..<event_count {
        process_event(plugin, in_events->get(event_index)) 
    }
}

@(rodata)
params_extension := clap_ext.Plugin_Params {
    count = get_num_params,
    get_info = params_get_info,
    get_value = param_get_value,
    value_to_text = param_convert_value_to_text,
    text_to_value = param_convert_text_to_value,
    flush = param_flush
}


plugin_state_save :: proc "c" (_plugin: ^clap.Plugin, stream: ^clap.OStream) -> bool {
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    // sync les parametres avant de les sauvegarder 
    
    num_params_written := stream.write(stream, raw_data(&plugin.main_param_values), size_of(f32)*len(ParamIDs))
    return u64(num_params_written) == size_of(f32) * len(ParamIDs)
}

plugin_state_load :: proc "c" (_plugin: ^clap.Plugin, stream: ^clap.IStream) -> bool {
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    num_params_read := stream.read(stream, raw_data(&plugin.main_param_values), size_of(f32) * len(ParamIDs))
    success: bool = num_params_read == i64(size_of(f32)) * len(ParamIDs)
    return success
}

@(rodata)
state_extension := clap_ext.Plugin_State {
    save = plugin_state_save,
    load = plugin_state_load,
}


is_gui_api_supported :: proc "c" (_plugin: ^clap.Plugin, api: cstring, id_floating: bool) -> bool { return false }
gui_get_preferred_api :: proc "c" (_plugin: ^clap.Plugin, api: ^cstring, is_floating: bool) -> bool { return false }
create_gui :: proc "c" (_plugin: ^clap.Plugin, api: cstring, is_floating: bool) -> bool { return false }
destroy_gui :: proc "c" (_plugin: ^clap.Plugin) {}
set_gui_scale :: proc "c" (_plugin: ^clap.Plugin, scale: f64) -> bool { return false }
get_gui_size :: proc "c" (_plugin: ^clap.Plugin, width, height: ^u32) -> bool { return false }
can_gui_resize :: proc "c" (_plugin: ^clap.Plugin) -> bool { return false }
get_gui_resize_hints :: proc "c" (_plugin: ^clap.Plugin, hints: ^clap_ext.Gui_Resize_Hints) -> bool { return false }
adjust_gui_size :: proc "c" (_plugin: ^clap.Plugin, width, height: ^u32) -> bool { return false }
set_gui_size :: proc "c" (_plugin: ^clap.Plugin, width, height: u32) -> bool { return false }
set_gui_parent :: proc "c" (_plugin: ^clap.Plugin, window: ^clap_ext.Window) -> bool { return false }
set_gui_transient :: proc "c" (_plugin: ^clap.Plugin, window: ^clap_ext.Window) -> bool { return false }
suggest_gui_title :: proc "c" (_plugin: ^clap.Plugin, title: cstring) {}
show_gui :: proc "c" (_plugin: ^clap.Plugin) -> bool { return false }
hide_gui :: proc "c" (_plugin: ^clap.Plugin) -> bool { return false }

@(rodata)
gui_extension := clap_ext.Plugin_Gui {
    is_api_supported = is_gui_api_supported,
    get_preferred_api = gui_get_preferred_api,
    create = create_gui,
    destroy = destroy_gui,
    set_scale = set_gui_scale,
    get_size = get_gui_size,
    can_resize = can_gui_resize,
    get_resize_hints = get_gui_resize_hints,
    adjust_size = adjust_gui_size,
    set_size = set_gui_size,
    set_parent = set_gui_parent,
    set_transient = set_gui_transient,
    suggest_title = suggest_gui_title,
    show = show_gui,
    hide = hide_gui,
}

plugin_init :: proc "c" (_plugin: ^clap.Plugin) -> bool {    
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    // init 
    for param_id, _ in ParamIDs {
            
        information: clap_ext.Param_Info
        
        params_get_info(_plugin, u32(param_id), &information)
        plugin.main_param_values[param_id] = f32(information.default_value)
        plugin.audio_param_values[param_id] = f32(information.default_value)
    }

    plugin.host_params = transmute(^clap_ext.Host_Params)plugin.host.get_extension(plugin.host, clap_ext.EXT_PARAMS)
    return true
}

plugin_destroy :: proc "c" (_plugin: ^clap.Plugin) {
    // plugin := transmute(^PluginData)_plugin.plugin_data
    context = runtime.default_context()

    free(_plugin.plugin_data)
}

plugin_activate :: proc "c" (_plugin: ^clap.Plugin, samplerate: f64, min_buffer_size: u32, max_buffer_size: u32) -> bool {
    plugin := transmute(^PluginData)_plugin.plugin_data
    context = runtime.default_context()
    
    plugin.samplerate = cast(f32)samplerate
    plugin.min_buffer_size = min_buffer_size
    plugin.max_buffer_size = max_buffer_size
    
    {
        error := vmem.arena_init_growing(&plugin.main_arena, 4 * mem.Megabyte)
        ensure(error == nil)
        allocator := vmem.arena_allocator(&plugin.main_arena)
    }
    
    {
        error := vmem.arena_init_growing(&plugin.echo_arena, 4 * mem.Megabyte)
        ensure(error == nil)
    
        allocator := vmem.arena_allocator(&plugin.echo_arena)
    
        echo := &plugin.echo
        buffer_size := u32(parameter_infos[ParamIDs.EchoTime].max * 0.001 * plugin.samplerate)
        echo.delay_lineL.buffer = make([]f32, buffer_size, allocator)
        echo.delay_lineR.buffer = make([]f32, buffer_size, allocator)
        
        init_delay_frac := ms_to_samples_frac(parameter_infos[.EchoTime].default_value, plugin.samplerate)

        ramped_value_init(&echo.delay_frac, init_delay_frac, max_buffer_size, allocator)
        ramped_value_init(&echo.feedback, parameter_infos[.EchoFeedback].default_value, max_buffer_size, allocator)
        ramped_value_init(&echo.mix, parameter_infos[.EchoMix].default_value, max_buffer_size, allocator)

        echo.delay_lineL.write_index = 0
        echo.delay_lineR.write_index = 0
        
        lfo_init(&echo.lfo, 0.5, plugin.samplerate, max_buffer_size, allocator)
        
        make_lowpass1(&echo.tone_filter, 10000.0, plugin.samplerate)
        biquad_reset(&echo.tone_filter)
    }
    
    { // reverb
    
        reverb:= &plugin.reverb
        
        error := vmem.arena_init_growing(&plugin.reverb_arena, 4*mem.Megabyte)
        ensure(error == nil)
        allocator := vmem.arena_allocator(&plugin.reverb_arena)
        
        allpass_max_delay := ms_to_samples(300.0, plugin.samplerate)
        
        early_times := [4]f32{4.77, 3.59, 12.73, 9.3}
        early_gains := [4]f32{0.7, 0.7, 0.6, 0.8}
                
        for index in 0..<len(reverb.early.allpasses) {
            filter := &reverb.early.allpasses[index]
            filter.delay_line.buffer = make([]f32, allpass_max_delay, allocator)            
            
            filter.delay_frac = ms_to_samples_frac(early_times[index], plugin.samplerate)
            filter.gain = early_gains[index]
        }
        
        fdn_max_delay := int(300.0 * 0.001 * samplerate)
        fdn_delays_ms := [4]f32{146.8, 152.13, 185.63, 168.18}
        reverb.late.feedback = 0.8
        
        for channel in 0..<len(reverb.late.delay_lines) {
            reverb.late.delay_lines[channel].buffer = make([]f32, fdn_max_delay, allocator)
            
            reverb.late.delay_frac[channel] = ms_to_samples_frac(fdn_delays_ms[channel], plugin.samplerate)
            
            make_lowpass1(&reverb.late.lp_filters[channel], 10000.0, plugin.samplerate)
        }
        
        reverb.input_buffer = make([]f32, max_buffer_size, allocator)        
        reverb.mix = plugin.audio_param_values[.ReverbMix]
    }
    
    // init et alloue tous ce qui a besoin de la samplerate ou de la block size
    
    return true 
}

plugin_deactivate :: proc "c" (_plugin: ^clap.Plugin) {
    // desalloue tout ce a été alloué dans activate
    plugin := transmute(^PluginData)_plugin.plugin_data
    context = runtime.default_context()

    vmem.arena_destroy(&plugin.main_arena)
    
    vmem.arena_destroy(&plugin.echo_arena)
    plugin.echo.delay_lineL.buffer = nil
    plugin.echo.delay_lineR.buffer = nil
    
    vmem.arena_destroy(&plugin.reverb_arena)
}

plugin_start_processing :: proc "c" (_plugin: ^clap.Plugin) -> bool { return true }

plugin_stop_processing :: proc "c" (_plugin: ^clap.Plugin) {}

plugin_reset :: proc "c" (_plugin: ^clap.Plugin) {}

process_event :: proc(plugin: ^PluginData, event: ^clap.Event_Header) {
    
    if event.space_id == clap.CORE_EVENT_SPACE_ID && event.event_type == .PARAM_VALUE {
        param_event := transmute(^clap.Event_Param_Value)event
        param_index := cast(ParamIDs)param_event.param_id
        
        handle_parameter_change(plugin, param_index, f32(param_event.value))
        plugin.audio_param_values[param_index] = f32(param_event.value)
    }
}

handle_parameter_change :: proc(plugin: ^PluginData, param_index: ParamIDs, value: f32) {
    plugin.audio_param_values[param_index] = value

    switch param_index {
        case .InGain: {
        }
        case .OutGain: {
        }
        case .EchoTime: {
            new_delay_frac := ms_to_samples_frac(value, plugin.samplerate)
            ramped_value_new_target(&plugin.echo.delay_frac, new_delay_frac, plugin.samplerate)
        }
        case .EchoFeedback: {
            ramped_value_new_target(&plugin.echo.feedback, value, plugin.samplerate)
        } 
        case .EchoTone: {
            make_lowpass1(&plugin.echo.tone_filter, value, plugin.samplerate)
        }
        case .EchoModFreq: {
            lfo_set_frequency(&plugin.echo.lfo, value, plugin.samplerate)
        }
        case .EchoModAmount: {
        
            mod_max :: 100.0
            plugin.echo.mod_amount = value * mod_max
        }
        case .EchoMix: {
            ramped_value_new_target(&plugin.echo.mix, value, plugin.samplerate)
        }
        
        case .ReverbDecay: {}
        case .ReverbSize: {}
        case .ReverbEarlyDiffusion: {}
        case .ReverbLateDiffusion: {}
        case .ReverbTone: {}
        case .ReverbMix: {
            plugin.reverb.mix = value
        }
    }    
}

sync_params_main_to_audio :: proc(plugin: ^PluginData, out_events: ^clap.Output_Events) {

    read_index := intrin.atomic_load(&plugin.main_to_audio_fifo.read_index)
    write_index := intrin.atomic_load(&plugin.main_to_audio_fifo.write_index)
    
    for read_index != write_index {
        plugin_event := &plugin.main_to_audio_fifo.events[read_index]
        
        switch plugin_event.event_type {
            case .GUI_VALUE_CHANGE: {
                handle_parameter_change(plugin, plugin_event.param_index, plugin_event.value)
                
                clap_event := clap.Event_Param_Value {
                    header = {
                        size = size_of(clap.Event_Param_Value),
                        time = 0,
                        space_id = clap.CORE_EVENT_SPACE_ID,
                        event_type = .PARAM_VALUE,
                        flags = .IS_LIVE,
                    },
                    param_id = u32(plugin_event.param_index),
                    cookie = nil,
                    note_id = -1,
                    port_index = -1,
                    channel = -1,
                    key = -1,
                    value = f64(plugin_event.value)
                }
                
                out_events->try_push(&clap_event.header)
            }            
            case .GUI_GESTURE_BEGIN: {
            
                clap_event := clap.Event_Param_Gesture {
                    header = {
                        size = size_of(clap.Event_Param_Gesture),
                        time = 0,
                        space_id = clap.CORE_EVENT_SPACE_ID,
                        event_type = .PARAM_GESTURE_BEGIN,
                        flags = .IS_LIVE,
                    },
                    param_id = u32(plugin_event.param_index),
                }
                
                out_events->try_push(&clap_event.header)
            }
            case .GUI_GESTURE_END: {
                clap_event := clap.Event_Param_Gesture {
                    header = {
                        size = size_of(clap.Event_Param_Gesture),
                        time = 0,
                        space_id = clap.CORE_EVENT_SPACE_ID,
                        event_type = .PARAM_GESTURE_END,
                        flags = .IS_LIVE,
                    },
                    param_id = u32(plugin_event.param_index),
                }
                
                out_events->try_push(&clap_event.header)                
            }
        }
        read_index += 1
        read_index &= (FIFO_SIZE-1)
    }
    intrin.atomic_store(&plugin.main_to_audio_fifo.read_index, read_index)
}


plugin_process :: proc "c" (_plugin: ^clap.Plugin, process: ^clap.Process) -> clap.Process_Status { 
    context = runtime.default_context()
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    // sync main to audio thread
    sync_params_main_to_audio(plugin, process.out_events)
    
    assert(process.audio_outputs_count == 1)
    assert(process.audio_inputs_count == 1)
    
    frame_count := process.frames_count 
    input_event_count := process.in_events->size()
    
    event_index : u32 = 0
    next_event_frame : u32 = input_event_count != 0 ? 0 : frame_count
    
    for current_frame_index : u32 = 0; current_frame_index < frame_count ; {
        for event_index < input_event_count && next_event_frame == current_frame_index {
            event: ^clap.Event_Header = process.in_events->get(event_index)
            if event.time != current_frame_index {
                next_event_frame = event.time
                break
            }
            
            process_event(plugin, event)
            event_index += 1
            
            if event_index == input_event_count {
                next_event_frame = frame_count
                break
            }
        }
        
        
        {
            // audio render
            nsamples : u32 = next_event_frame - current_frame_index
            
            inputL : []f32 = process.audio_inputs[0].data32[0][current_frame_index:current_frame_index + nsamples]
            inputR : []f32 = process.audio_inputs[0].data32[1][current_frame_index:current_frame_index + nsamples]
            
            outputL : []f32 = process.audio_outputs[0].data32[0][current_frame_index:current_frame_index + nsamples]
            outputR : []f32 = process.audio_outputs[0].data32[1][current_frame_index:current_frame_index + nsamples]
            
            
            echo_process(&plugin.echo, inputL, inputR)
            
            reverb_process(&plugin.reverb, inputL, inputR)
            
            for index in 0..<len(inputL) {
                inputL[index] = clamp(inputL[index], -1.0, 1.0)
                inputR[index] = clamp(inputR[index], -1.0, 1.0)
            }
            
            copy(outputL, inputL)
            copy(outputR, inputR)
        }
        
        current_frame_index = next_event_frame
    }
    
    return .CONTINUE
}

plugin_get_extension :: proc "c" (_plugin: ^clap.Plugin, id: cstring) -> rawptr { 
    switch id {
        case clap_ext.EXT_AUDIO_PORTS: { return &audio_port_extension }
        case clap_ext.EXT_PARAMS:      { return &params_extension }
        case clap_ext.EXT_STATE:       { return &state_extension }
        case clap_ext.EXT_GUI:         { return &gui_extension }
    }

    return nil 
}

plugin_on_main_thread :: proc "c" (_plugin: ^clap.Plugin) {}


clap_plugin := clap.Plugin {
    desc             = &plugin_descriptor,
    plugin_data      = nil,
    init             = plugin_init,
    destroy          = plugin_destroy,
    activate         = plugin_activate,
    deactivate       = plugin_deactivate,
    start_processing = plugin_start_processing,
    stop_processing  = plugin_stop_processing,
    reset            = plugin_reset,
    process          = plugin_process,
    get_extension    = plugin_get_extension,
    on_main_thread   = plugin_on_main_thread,
}

plugin_descriptor : clap.Plugin_Descriptor

get_plugin_count :: proc "c" (factory: ^clap.Plugin_Factory) -> u32 { return 1 }

get_plugin_descriptor :: proc "c" (factory: ^clap.Plugin_Factory, index: u32) -> ^clap.Plugin_Descriptor {
    return index == 0 ? &plugin_descriptor : nil
}

create_plugin :: proc "c" (factory: ^clap.Plugin_Factory, host: ^clap.Host, plugin_id: cstring) -> ^clap.Plugin {
    
    if plugin_id != plugin_descriptor.id {
        return nil
    }
    
    context = runtime.default_context()
    plugin := new(PluginData)
    plugin.host = host
    plugin.plugin = clap_plugin
    plugin.plugin.plugin_data = plugin
    
    return &plugin.plugin
}

plugin_factory := clap.Plugin_Factory {
    get_plugin_count = get_plugin_count,
    get_plugin_descriptor = get_plugin_descriptor,
    create_plugin = create_plugin,
}

plugin_features: []cstring 

lib_init :: proc "c" (path: cstring) -> bool {
    context = runtime.default_context()

    plugin_descriptor.clap_version = clap.CLAP_VERSION
    plugin_descriptor.id           = "hermes140.clap_ambient"
    plugin_descriptor.name         = "Clap Ambient"
    plugin_descriptor.vendor       = "Hermes140"
    plugin_descriptor.url          = ""
    plugin_descriptor.manual_url   = ""
    plugin_descriptor.support_url  = ""
    plugin_descriptor.version      = "0.1"
    plugin_descriptor.description  = ""

    if slice.is_empty(plugin_features) {
        plugin_features = make([]cstring, 6)
    }
    plugin_features[0] = clap.PLUGIN_FEATURE_AUDIO_EFFECT
    plugin_features[1] = clap.PLUGIN_FEATURE_STEREO
    plugin_features[2] = clap.PLUGIN_FEATURE_MULTI_EFFECTS
    plugin_features[3] = clap.PLUGIN_FEATURE_REVERB
    plugin_features[4] = clap.PLUGIN_FEATURE_DELAY
    plugin_features[5] = nil

    plugin_descriptor.features = raw_data(plugin_features)


    clap_plugin.desc             = &plugin_descriptor
    clap_plugin.init             = plugin_init
    clap_plugin.destroy          = plugin_destroy
    clap_plugin.activate         = plugin_activate
    clap_plugin.deactivate       = plugin_deactivate
    clap_plugin.start_processing = plugin_start_processing
    clap_plugin.stop_processing  = plugin_stop_processing
    clap_plugin.reset            = plugin_reset
    clap_plugin.process          = plugin_process
    clap_plugin.get_extension    = plugin_get_extension
    clap_plugin.on_main_thread   = plugin_on_main_thread

    return true
}

lib_deinit :: proc "c" () {
    context = runtime.default_context()
    delete(plugin_features)
}

lib_get_factory :: proc "c" (id: cstring) -> rawptr {
    return id == clap.PLUGIN_FACTORY_ID ? &plugin_factory : nil
}

@(export)
clap_entry := clap.Plugin_Entry {
    clap_version = clap.CLAP_VERSION,
    init = lib_init,
    deinit = lib_deinit,
    get_factory = lib_get_factory,
}
