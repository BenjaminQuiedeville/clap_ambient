package clap_ambient

import "base:runtime"
import intrin "base:intrinsics"
import "core:math"
import win32 "core:sys/windows"
import "core:mem"
import vmem "core:mem/virtual"
import "core:slice"
import "core:fmt"
import "core:strings"
import "core:strconv"
import opengl "vendor:OpenGL"

import imgui "../odin-imgui"
import imgui_win32 "../odin-imgui/imgui_impl_win32"
import imgui_opengl "../odin-imgui/imgui_impl_opengl3"
import clap  "../clap-odin"
import clap_ext "../clap-odin/ext"

BUILD_CONFIG :: #config(BUILD_CONFIG, "debug")

PLUGIN_DESC_ID :: "hermes140.clap_ambient_" + BUILD_CONFIG
PLUGIN_NAME    :: "Clap Ambient " + BUILD_CONFIG

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
    imgui_flags: imgui.SliderFlags,
    clap_param_flags: clap_ext.Param_Info_Flag,
}

@(rodata)
parameter_infos := [ParamIDs]ParamInfo {
    .InGain = {
        name = "Input Gain (dB)", min = -60.0, max = 6.0, default_value = 0.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
        clap_param_flags = .AUTOMATABLE,
    },
    .OutGain = {
        name = "Output Gain (dB)", min = -60.0, max = 6.0, default_value = 0.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
        clap_param_flags = .AUTOMATABLE,
    },

    .EchoTime = {
        name = "Delay Time", min = 1.0, max = 2000.0, default_value = 300.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
        clap_param_flags = .AUTOMATABLE
    },
    .EchoFeedback = {
        name = "Feedback", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
        clap_param_flags = .AUTOMATABLE
    },
    .EchoTone = {
        name = "Echo tone", min = 500.0, max = 20000.0, default_value = 20000.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange, .Logarithmic}, 
        clap_param_flags = .AUTOMATABLE,
    },
    .EchoModFreq = {
        name = "Echo mod freq", min = 0.0, max = 10.0, default_value = 1.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
        clap_param_flags = .AUTOMATABLE,
    },
    .EchoModAmount = {
        name = "Echo mod amount", min = 0.0, max = 1.0, default_value = 0.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
        clap_param_flags = .AUTOMATABLE,
    },
    .EchoMix = {
        name = "Mix", min = 0.0, max = 1.0, default_value = 0.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
        clap_param_flags = .AUTOMATABLE
    },

    .ReverbDecay = {
        name = "Reverb decay", min = 0.0, max = 100.0, default_value = 3.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
        clap_param_flags = .AUTOMATABLE,     
    },
    .ReverbSize = {
        name = "Reverb size", min = 1.0, max = 5.0, default_value = 1.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
        clap_param_flags = .AUTOMATABLE,
    },
    .ReverbEarlyDiffusion = {
        name = "Reverb Early Diffusion", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
        clap_param_flags = .AUTOMATABLE,
    },
    .ReverbLateDiffusion = {
        name = "Reverb Late Diffusion", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
        clap_param_flags = .AUTOMATABLE,
    },
    .ReverbTone = {
        name = "Reverb Tone", min = 200.0, max = 20000.0, default_value = 15000.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange, .Logarithmic},
        clap_param_flags = .AUTOMATABLE,
    },
    .ReverbMix = {
        name = "Reverb mix", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
        clap_param_flags = .AUTOMATABLE,
    },
}

PIf32 :: f32(math.PI)
PI_4f32 :: f32(math.PI / 4)

dbtoa :: #force_inline proc(x: f32) -> f32 { return math.pow(10.0, x * 0.05) }
atodb :: #force_inline proc(x: f32) -> f32 { return 20.0 * math.log10(x) }

scale :: #force_inline proc(x, min, max, newmin, newmax, curve: f32) -> f32 {
    return math.pow((x - min) / (max - min), curve) * (newmax - newmin) + newmin
}

scale_linear :: #force_inline proc(x, min, max, newmin, newmax: f32) -> f32 {
    return (x - min) / (max - min) * (newmax - newmin) + newmin
}

apply_gain_linear :: #force_inline proc(buffer: []f32, gain: f32) {
    for &sample in buffer {
        sample *= gain
    }
}

add_buffers :: #force_inline proc(dest, source: []f32) {
    for &sample, index in dest {
        sample += source[index]
    }
}

ms_to_samples_frac :: #force_inline proc(x, samplerate: f32) -> f32 { return x * 0.001*samplerate }
ms_to_samples :: #force_inline proc(x, samplerate: f32) -> int { return int(x * 0.001*samplerate) }

samples_to_ms :: #force_inline proc(x, samplerate: f32) -> f32 { return x * 1000.0 / samplerate }

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
    
    value.value_buffer = nil
    if (buffer_size != 0) {
        value.value_buffer = make([]f32, buffer_size, allocator)
        slice.zero(value.value_buffer)
    }
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
    assert(value.value_buffer != nil, "RampedValue cannot fill buffer, not allocated")   
    
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

delay_line_read_sample_lagrange :: proc(dl: DelayLine, read_position: f32) -> f32  {    
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
    
    assert(!math.is_nan(out_sample))
    
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

FDN_ORDER :: 8
@rodata fdn_delays_ms := [FDN_ORDER]f32{ 12.723904, 50.03751, 64.207954, 108.86561, 130.90741, 173.62048, 188.95348, 217.13364 }

Reverb :: struct {
    // faire 4 allpass et un FDN4 pour commencer
    // @TODO tester la chaine de allpass (prendre les valeurs de la progenitor)
    // APRES, commencer à construire un FDN4 PUIS un FDN16
    // expérimenter avec différentes formes de allpass (ordre 2, multitap...)
    
    early: struct {
        allpasses: [4]AllpassDelay2,
        
        in_lp: Biquad,
        lp_state: [2]f32,
        
        in_hp: Biquad,
        hp_state: [2]f32,
    },
    
    late: struct {
        delay_lines: [FDN_ORDER]DelayLine,
        delays_frac: [FDN_ORDER]RampedValue,
        
        allpasses: [FDN_ORDER]AllpassDelay,
        
        lp_filters: [FDN_ORDER]Biquad,
        lp_state: [FDN_ORDER][2]f32,
        
        lfos: [FDN_ORDER]LFO,
        feedback: RampedValue,
    },
    
    input_buffer: []f32,
    early_stage_buffer: []f32,
    output_buffers: [2][]f32,
    mix: f32,
}

//github.com/Signalsmith-Audio/reverb-example-code/blob/main/reverb-example-code.h
reverb_compute_feedback :: proc(rt60: f32, max_delay_ms: f32) -> f32 {    
    loops_per_rt60 := rt60/(max_delay_ms * 0.001 * 1.5)
    db_per_cycle := -60.0/loops_per_rt60
    
    return math.pow(10.0, db_per_cycle*0.05)
}

reverb_process :: proc(reverb: ^Reverb, bufferL: []f32, bufferR: []f32) {
    
    //early stages
    nsamples := u32(len(bufferL))
        
    reverb_input_buf := reverb.input_buffer[:nsamples]
    reverb_early_buf := reverb.early_stage_buffer[:nsamples]
    output_buffers: [2][]f32 = { reverb.output_buffers[0][:nsamples], 
                                 reverb.output_buffers[1][:nsamples] }
    
    for index in 0..<nsamples {    
        reverb_input_buf[index] = (bufferL[index] + bufferR[index])*0.5
    }

    copy(reverb_early_buf, reverb_input_buf)    
    allpass2_process_buffer(&reverb.early.allpasses[0], reverb_early_buf)
    allpass2_process_buffer(&reverb.early.allpasses[1], reverb_early_buf)
    
    copy(output_buffers[0], reverb_early_buf)
    copy(output_buffers[1], reverb_early_buf)


    copy(reverb_early_buf, reverb_input_buf)
    allpass2_process_buffer(&reverb.early.allpasses[2], reverb_early_buf)
    allpass2_process_buffer(&reverb.early.allpasses[3], reverb_early_buf)
    
    add_buffers(output_buffers[0], reverb_early_buf)
    add_buffers(output_buffers[1], reverb_early_buf)

    { //late  
    // screams SIMD
        @static feedback_matrix := [FDN_ORDER][FDN_ORDER]f32 { {1,  1,  1,  1,  1,  1,  1,  1},
                                                               {1, -1,  1, -1,  1, -1,  1, -1},
                                                               {1,  1, -1, -1,  1,  1, -1, -1},
                                                               {1, -1, -1,  1,  1, -1, -1,  1},
                                                               {1,  1,  1,  1, -1, -1, -1, -1},
                                                               {1, -1,  1, -1, -1,  1, -1,  1},
                                                               {1,  1, -1, -1, -1, -1,  1,  1},
                                                               {1, -1, -1,  1, -1,  1,  1, -1}, }

        mod_amount : f32 = 5.0
        for channel in 0..<FDN_ORDER {
            lfo_fill_buffers(&reverb.late.lfos[channel], nsamples)
        }
        
        delay_outputs: [FDN_ORDER]f32
        mixing_outputs: [FDN_ORDER]f32
        
        for index in 0..<nsamples {

            feedback := ramped_value_step(&reverb.late.feedback)
            
            for &delay_frac in reverb.late.delays_frac {
                ramped_value_step(&delay_frac)
            }

            // fdn_in_sample := output_buffers[0][index]
            fdn_in_sample := reverb_early_buf[index]
            
            
            for channel in 0..<FDN_ORDER {
                read_index_frac := (f32(reverb.late.delay_lines[channel].write_index) 
                                    - reverb.late.delays_frac[channel].current_value 
                                    + reverb.late.lfos[channel].sin_buffer[index] * mod_amount)
                                    
                delay_outputs[channel] = delay_line_read_sample_lagrange(reverb.late.delay_lines[channel], read_index_frac)
            }
            
            output_buffers[0][index] += delay_outputs[0]
            output_buffers[1][index] += delay_outputs[1]
            
            slice.zero(mixing_outputs[:])
            
            mixing_gain : f32 : 0.35355339059327373
            for channel in 0..<FDN_ORDER {
                for matrix_index in 0..<FDN_ORDER {
                    mixing_outputs[channel] += delay_outputs[matrix_index]*feedback_matrix[channel][matrix_index]
                }
                mixing_outputs[channel] *= mixing_gain
            }            
            
            for channel in 0..<FDN_ORDER {
                delay_in := biquad_process_sample(reverb.late.lp_filters[channel], reverb.late.lp_state[channel][:], mixing_outputs[channel])
            
                delay_in *= feedback
                delay_in += fdn_in_sample
                delay_line_push_sample(&reverb.late.delay_lines[channel], delay_in)
            }
        }
    }

    for index in 0..<nsamples {
        bufferL[index] = math.lerp(bufferL[index], output_buffers[0][index], reverb.mix)
        bufferR[index] = math.lerp(bufferR[index], output_buffers[1][index], reverb.mix)
    }
    
    apply_gain_linear(bufferL, 0.5)    
    apply_gain_linear(bufferR, 0.5)    
}

ProgenitorReverb :: struct {}


Echo :: struct {
    delay_lineL: DelayLine,
    delay_lineR: DelayLine,
    delay_frac: RampedValue,
    feedback: RampedValue,
    mix: RampedValue,
    tone_filter: Biquad,
    filter_stateL: [2]f32,
    filter_stateR: [2]f32,
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
    
        feedback_sampleL = biquad_process_sample(echo.tone_filter, echo.filter_stateL[:], feedback_sampleL)
        feedback_sampleR = biquad_process_sample(echo.tone_filter, echo.filter_stateR[:], feedback_sampleR)
    
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
    lfo.sin_value = 0.0
    lfo.cos_buffer = make([]f32, buffer_size, allocator)
    lfo.sin_buffer = make([]f32, buffer_size, allocator)
    slice.zero(lfo.cos_buffer)
    slice.zero(lfo.sin_buffer)

    lfo_set_frequency(lfo, freq, samplerate)
}

lfo_set_frequency :: #force_inline proc (lfo: ^LFO, freq: f32, samplerate: f32) {
    lfo.param = 2.0 * math.sin(PIf32 * freq/samplerate)
}

lfo_fill_buffers :: proc(lfo: ^LFO, nsamples: u32) {
    assert(lfo.cos_buffer != nil && lfo.sin_buffer != nil, "LFO: value buffers not allocated")

    for index in 0..<nsamples {
        lfo_step(lfo, index)
    }
}

lfo_step :: #force_inline proc(lfo: ^LFO, index: u32) {
    lfo.cos_value -= lfo.param * lfo.sin_value
    lfo.sin_value += lfo.param * lfo.cos_value
    
    lfo.cos_value = clamp(lfo.cos_value, -0.5, 0.5)
    lfo.sin_value = clamp(lfo.sin_value, -0.5, 0.5)
    
    lfo.cos_buffer[index] =  2.0 * lfo.cos_value
    lfo.sin_buffer[index] =  2.0 * lfo.sin_value
}

Biquad :: struct {
    b0, b1, b2: f32,
    a1, a2: f32, 
    gain: f32,
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

biquad_process_sample :: #force_inline proc(f: Biquad, state: []f32, sample: f32) -> f32 {
    w := sample + f.a1*state[0] + f.a2*state[1]
    out_sample := f.b0*w + f.b1*state[0] + f.b2*state[1]
    
    state[1] = state[0]
    state[0] = w
    return out_sample
}


biquad_process :: proc(f: Biquad, state: []f32, buffer: []f32) {
    
    for index in 0..<len(buffer) {
        buffer[index] = biquad_process_sample(f, state, buffer[index])
    }
}

AllpassDelay :: struct {
    delay_line: DelayLine,
    gain: f32,
    delay_frac: f32
}

allpass_init :: proc(allpass: ^AllpassDelay, buffer_size: u32, init_delay_frac, init_gain: f32, allocator: runtime.Allocator) {
    
    allpass.delay_line.buffer = make([]f32, buffer_size, allocator)
    slice.zero(allpass.delay_line.buffer)
    
    allpass.delay_frac = init_delay_frac
    allpass.gain = init_gain
}

allpass_process_buffer :: proc(ap: ^AllpassDelay, buffer: []f32) {
    
    for &sample in buffer {
        sample = allpass_process_sample(ap, sample)
    }
}

allpass_process_sample :: #force_inline proc(ap: ^AllpassDelay, in_sample: f32) -> f32 {
        
    // lire le buffer
    // output = delay_sample - input*gain
    // ecrire input + delay_sample*gain dans le buffer
    
    read_position := f32(ap.delay_line.write_index) - ap.delay_frac
    
    delay_sample := delay_line_read_sample_lagrange(ap.delay_line, read_position)
    out_sample := delay_sample + in_sample*ap.gain
    
    feedback_sample := in_sample - delay_sample * ap.gain
    delay_line_push_sample(&ap.delay_line, feedback_sample)
    
    return out_sample
}

AllpassDelay2 :: struct {
    delay_line_outer: DelayLine,
    delay_line_inner: DelayLine,
    gain_outer, gain_inner: f32,
    delay_frac_outer, delay_frac_inner: f32
}

allpass2_init :: proc(allpass: ^AllpassDelay2, 
                      buffer_size_outer, buffer_size_inner: int, 
                      init_delay_frac_outer, init_delay_frac_inner: f32,
                      init_gain_outer, init_gain_inner: f32, 
                      allocator: runtime.Allocator)
{
    allpass.delay_line_outer.buffer = make([]f32, buffer_size_outer, allocator)
    slice.zero(allpass.delay_line_outer.buffer)
    
    allpass.delay_line_inner.buffer = make([]f32, buffer_size_inner, allocator)
    slice.zero(allpass.delay_line_inner.buffer)
    
    allpass.delay_frac_outer = init_delay_frac_outer
    allpass.delay_frac_inner = init_delay_frac_inner
    
    allpass.gain_outer = init_gain_outer
    allpass.gain_inner = init_gain_inner
    
}


allpass2_process_buffer :: proc(ap: ^AllpassDelay2, buffer: []f32) {
    for &sample in buffer {
        sample = allpass2_process_sample(ap, sample)
    }
}


allpass2_process_sample :: #force_inline proc(ap: ^AllpassDelay2, in_sample: f32) -> f32 {

    read_position_outer := f32(ap.delay_line_outer.write_index) - ap.delay_frac_outer
    read_position_inner := f32(ap.delay_line_inner.write_index) - ap.delay_frac_inner
    
    delay_sample_outer := delay_line_read_sample_lagrange(ap.delay_line_outer, read_position_outer)
    delay_sample_inner := delay_line_read_sample_lagrange(ap.delay_line_inner, read_position_inner)
    
    inner_out := delay_sample_inner + delay_sample_outer*ap.gain_inner
    
    out_sample := inner_out + in_sample*ap.gain_outer
    delay_line_push_sample(&ap.delay_line_outer, in_sample - out_sample*ap.gain_outer)
    delay_line_push_sample(&ap.delay_line_inner, delay_sample_outer - inner_out*ap.gain_inner)

    return out_sample
}


Looper :: struct {}
GranularDelay :: struct {}

GUI :: struct {
    window_class: win32.WNDCLASSW,
    window: win32.HWND,
    imgui_context: ^imgui.Context,
    opengl_context: win32.HGLRC,
    device_context: win32.HDC,
    width, height: int,
    
    test_slider_value :f32,
    test_slider_value2 :f32,
}

PluginData :: struct {
    plugin: clap.Plugin,
    host: ^clap.Host,
    host_params: ^clap_ext.Host_Params,

    max_buffer_size: u32,
    min_buffer_size: u32,
    samplerate: f32,

    main_param_values: [ParamIDs]f32,
    audio_param_values: [ParamIDs]f32,
    param_is_in_edit: [ParamIDs]bool, 
    main_to_audio_fifo: EventFIFO,
    
    input_gain: RampedValue,
    output_gain: RampedValue,

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
    out_value^, _ = strconv.parse_f64(in_string)
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


GImGui: ^imgui.Context

is_gui_api_supported :: proc "c" (_plugin: ^clap.Plugin, api: cstring, is_floating: bool) -> bool { 
    return string(api) == clap_ext.WINDOW_API_WIN32 && !is_floating
}

gui_get_preferred_api :: proc "c" (_plugin: ^clap.Plugin, api: ^cstring, is_floating: ^bool) -> bool { 
    api^ = clap_ext.WINDOW_API_WIN32
    is_floating^ = false
    return true 
}

make_slider :: proc(plugin: ^PluginData, param_index: ParamIDs, format: string) {
    
    slider_has_changed := imgui.SliderFloat(strings.clone_to_cstring(parameter_infos[param_index].name),
                                            &plugin.main_param_values[param_index],
                                            parameter_infos[param_index].min,
                                            parameter_infos[param_index].max,
                                            strings.clone_to_cstring(format), parameter_infos[param_index].imgui_flags)
                                            
    if slider_has_changed {
        
        if !plugin.param_is_in_edit[param_index] {
            plugin.param_is_in_edit[param_index] = true
            
            main_push_event_to_audio(plugin, param_index, .GUI_GESTURE_BEGIN, plugin.main_param_values[param_index])
        }
        
        main_push_event_to_audio(plugin, param_index, .GUI_VALUE_CHANGE, plugin.main_param_values[param_index])
    } else {
        
        if plugin.param_is_in_edit[param_index] {
            plugin.param_is_in_edit[param_index] = false
            
            main_push_event_to_audio(plugin, param_index, .GUI_GESTURE_END, plugin.main_param_values[param_index])
        }    
    }
}

window_procedure :: proc "system" (window: win32.HWND, message: win32.UINT, wParam: win32.WPARAM, lParam: win32.LPARAM) -> win32.LRESULT {
    context = runtime.default_context()
    plugin := transmute(^PluginData)win32.GetWindowLongPtrW(window, win32.GWLP_USERDATA)
    
    if plugin == nil {
        return win32.DefWindowProcW(window, message, wParam, lParam)
    }

    gui := &plugin.gui
    
    imgui.SetCurrentContext(gui.imgui_context)
    
    if imgui_win32.WndProcHandler(window, message, wParam, lParam) != 0 {
        return 1
    }

    switch message {
        case win32.WM_TIMER: {
            plugin_sync_audio_to_main(plugin)            
            
            result := win32.wglMakeCurrent(gui.device_context, gui.opengl_context)            
            
            imgui_opengl.NewFrame()
            imgui_win32.NewFrame()
            imgui.NewFrame()
            
            viewport := imgui.GetMainViewport()
            imgui.SetNextWindowPos(viewport.WorkPos)
            imgui.SetNextWindowSize(viewport.WorkSize)
            
            io := imgui.GetIO()
                        
            {
                open: bool = true
                imgui.Begin("clap ambient plugin", &open, imgui.WindowFlags_NoDecoration)

                make_slider(plugin, .InGain, "%.2f")
                make_slider(plugin, .OutGain, "%.2f")

                imgui.SeparatorText("Echo")
                make_slider(plugin, .EchoTime, "%.2f")
                make_slider(plugin, .EchoFeedback, "%.2f")
                make_slider(plugin, .EchoTone, "%.2f")
                make_slider(plugin, .EchoModFreq, "%.2f")
                make_slider(plugin, .EchoModAmount, "%.2f")
                make_slider(plugin, .EchoMix, "%.2f")
    
                imgui.SeparatorText("Reverb")
                make_slider(plugin, .ReverbDecay, "%.2f")
                make_slider(plugin, .ReverbSize, "%.2f")
                make_slider(plugin, .ReverbEarlyDiffusion, "%.2f")
                make_slider(plugin, .ReverbLateDiffusion, "%.2f")
                make_slider(plugin, .ReverbTone, "%.2f")
                make_slider(plugin, .ReverbMix, "%.2f")

                if imgui.Button("Clear all buffers") {
                    // clear all buffers
                }
                
                imgui.End()
            }
            
            clear_color := imgui.Vec4 {0.45, 0.55, 0.6, 1.0}
            imgui.Render()
            opengl.Viewport(0, 0, i32(gui.width), i32(gui.height))
            opengl.ClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w)
            opengl.Clear(opengl.COLOR_BUFFER_BIT)
            
            imgui_opengl.RenderDrawData(imgui.GetDrawData())
            
            win32.SwapBuffers(gui.device_context)
            
            imgui.SetCurrentContext(nil)
            win32.wglMakeCurrent(nil, nil)
            return 0
        }
        
        case: {
            return win32.DefWindowProcW(window, message, wParam, lParam)
        }
    }

    return 0
}


create_gui :: proc "c" (_plugin: ^clap.Plugin, api: cstring, is_floating: bool) -> bool {
    if !is_gui_api_supported(_plugin, api, is_floating) { return false }
    
    plugin := transmute(^PluginData)_plugin.plugin_data
    gui := &plugin.gui
    
    mem.zero(&gui.window_class, size_of(gui.window_class))
    gui.window_class.lpfnWndProc = window_procedure
    gui.window_class.cbWndExtra = size_of(^PluginData)
    gui.window_class.lpszClassName = PLUGIN_DESC_ID
    gui.window_class.hCursor = win32.LoadCursorA(nil, win32.IDC_ARROW)
    gui.window_class.style = win32.CS_OWNDC | win32.CS_DBLCLKS
    win32.RegisterClassW(&gui.window_class)
    
    gui.width = 600
    gui.height = 400
    gui.window = win32.CreateWindowW(gui.window_class.lpszClassName, 
                                    PLUGIN_NAME, 
                                    win32.WS_CHILD | win32.WS_VISIBLE | win32.WS_CLIPSIBLINGS, 
                                    win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, 
                                    i32(gui.width), i32(gui.height),
                                    win32.GetDesktopWindow(),
                                    nil, gui.window_class.hInstance, nil)
                                       
    win32.SetWindowLongPtrW(gui.window, win32.GWLP_USERDATA, transmute(win32.LONG_PTR)plugin)
    return true
}

destroy_gui :: proc "c" (_plugin: ^clap.Plugin) {
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    plugin_hidden := hide_gui(_plugin)
    
    win32.DestroyWindow(plugin.gui.window)
    plugin.gui.window = nil
    win32.UnregisterClassW(PLUGIN_DESC_ID, nil)
}

set_gui_scale :: proc "c" (_plugin: ^clap.Plugin, scale: f64) -> bool { return false }
get_gui_size :: proc "c" (_plugin: ^clap.Plugin, width, height: ^u32) -> bool { 
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    width^ = u32(plugin.gui.width)
    height^ = u32(plugin.gui.height)
    return true
}

can_gui_resize :: proc "c" (_plugin: ^clap.Plugin) -> bool { return false }
get_gui_resize_hints :: proc "c" (_plugin: ^clap.Plugin, hints: ^clap_ext.Gui_Resize_Hints) -> bool { return false }
adjust_gui_size :: proc "c" (_plugin: ^clap.Plugin, width, height: ^u32) -> bool { return get_gui_size(_plugin, width, height) }
set_gui_size :: proc "c" (_plugin: ^clap.Plugin, width, height: u32) -> bool { return true }

set_gui_parent :: proc "c" (_plugin: ^clap.Plugin, parent_window: ^clap_ext.Window) -> bool {
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    win32.SetParent(plugin.gui.window, transmute(win32.HWND)parent_window.handle.win32)
    return true
}

set_gui_transient :: proc "c" (_plugin: ^clap.Plugin, window: ^clap_ext.Window) -> bool { return false }
suggest_gui_title :: proc "c" (_plugin: ^clap.Plugin, title: cstring) {}

show_gui :: proc "c" (_plugin: ^clap.Plugin) -> bool { 
    context = runtime.default_context()
    plugin := transmute(^PluginData)_plugin.plugin_data
    gui := &plugin.gui

    win32.ShowWindow(gui.window, win32.SW_SHOW)
    win32.SetFocus(gui.window)
    
    done := false
    create_device_GL: {
        device_context := win32.GetDC(gui.window)
        pfd: win32.PIXELFORMATDESCRIPTOR
        pfd.nSize = size_of(pfd)
        pfd.nVersion = 1
        pfd.dwFlags = win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL | win32.PFD_DOUBLEBUFFER
        pfd.iPixelType = win32.PFD_TYPE_RGBA
        pfd.cColorBits = 32
        
        pf := win32.ChoosePixelFormat(device_context, &pfd)
        if pf == 0{
            done = false
            break create_device_GL
        }

        if win32.SetPixelFormat(device_context, pf, &pfd) == win32.FALSE {
            done = false
            break create_device_GL
        }
        win32.ReleaseDC(gui.window, device_context)
    
        gui.device_context = win32.GetDC(gui.window)
        if gui.opengl_context == nil {
            gui.opengl_context = win32.wglCreateContext(gui.device_context)
        }    
        done = true
    }

    if !done {
        win32.wglMakeCurrent(nil, nil)
        win32.ReleaseDC(gui.window, gui.device_context)
        win32.DestroyWindow(gui.window)
        win32.UnregisterClassW(PLUGIN_DESC_ID, nil)
        return false
    }
    
    result := win32.wglMakeCurrent(gui.device_context, gui.opengl_context)
    result = win32.ShowWindow(gui.window, win32.SW_SHOW)
    result = win32.UpdateWindow(gui.window)

    imgui.CHECKVERSION()
    if GImGui != nil  { GImGui = nil }    
    imgui.SetCurrentContext(nil)
    gui.imgui_context = imgui.CreateContext()
    imgui.SetCurrentContext(gui.imgui_context)
    
    imgui_io := imgui.GetIO()
    imgui_io.ConfigFlags = { .NoKeyboard }

    imgui.StyleColorsDark()
    
    is_init := imgui_win32.InitForOpenGL(gui.window)
    is_init = imgui_opengl.Init()    
    opengl.load_up_to(3, 2, win32.gl_set_proc_address)

    win32.SetTimer(gui.window, 1, 30, nil)
    
    return true
}

hide_gui :: proc "c" (_plugin: ^clap.Plugin) -> bool { 
    context = runtime.default_context()
    plugin := transmute(^PluginData)_plugin.plugin_data
    gui := &plugin.gui

    win32.ShowWindow(gui.window, win32.SW_HIDE)
    win32.SetFocus(gui.window)
    
    win32.wglMakeCurrent(gui.device_context, gui.opengl_context)
    imgui.SetCurrentContext(gui.imgui_context)
    
    imgui_opengl.Shutdown()
    imgui_win32.Shutdown()
    imgui.DestroyContext()
    gui.imgui_context = nil
    imgui.SetCurrentContext(nil)
    
    win32.wglMakeCurrent(nil, nil)
    win32.ReleaseDC(gui.window, gui.device_context)
    
    win32.wglDeleteContext(gui.opengl_context)
    gui.opengl_context = nil
    gui.device_context = nil
    
    win32.KillTimer(gui.window, 1)
    
    return true
}

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
        
        ramped_value_init(&plugin.input_gain, dbtoa(parameter_infos[.InGain].default_value), max_buffer_size, allocator)
        ramped_value_init(&plugin.output_gain, dbtoa(parameter_infos[.OutGain].default_value), max_buffer_size, allocator)
    
    }
    
    {
        error := vmem.arena_init_growing(&plugin.echo_arena, 4 * mem.Megabyte)
        ensure(error == nil)
    
        allocator := vmem.arena_allocator(&plugin.echo_arena)
    
        echo := &plugin.echo
        // prendre en compte l'amplitude de la modulation dans l'allocation des buffers de delays
        buffer_size := cast(u32)ms_to_samples(parameter_infos[ParamIDs.EchoTime].max, plugin.samplerate) + 100
        echo.delay_lineL.buffer = make([]f32, buffer_size, allocator)
        echo.delay_lineR.buffer = make([]f32, buffer_size, allocator)
        slice.zero(echo.delay_lineL.buffer)
        slice.zero(echo.delay_lineR.buffer)
        
        init_delay_frac := ms_to_samples_frac(parameter_infos[.EchoTime].default_value, plugin.samplerate)

        ramped_value_init(&echo.delay_frac, init_delay_frac, max_buffer_size, allocator)
        ramped_value_init(&echo.feedback, parameter_infos[.EchoFeedback].default_value, max_buffer_size, allocator)
        ramped_value_init(&echo.mix, parameter_infos[.EchoMix].default_value, max_buffer_size, allocator)

        echo.delay_lineL.write_index = 0
        echo.delay_lineR.write_index = 0
        
        lfo_init(&echo.lfo, 0.5, plugin.samplerate, max_buffer_size, allocator)
        
        make_lowpass1(&echo.tone_filter, plugin.audio_param_values[.ReverbTone], plugin.samplerate)
    }
    
    { // reverb
    
        reverb:= &plugin.reverb
        
        error := vmem.arena_init_growing(&plugin.reverb_arena, 4*mem.Megabyte)
        ensure(error == nil)
        allocator := vmem.arena_allocator(&plugin.reverb_arena)
        
        early_allpass_alloc_size := ms_to_samples(50.0, plugin.samplerate)
        
        early_times_outer := [4]f32{7.56, 21.73, 8.50, 33.07}
        early_times_inner := [4]f32{17.01, 37.84, 21.73, 39.69}
        
        early_gains_outer := [4]f32{0.7, 0.4, 0.7, 0.4}
        early_gains_inner := [4]f32{0.5, 0.4, 0.5, 0.4}
                        
        for &allpass, index in reverb.early.allpasses {
            allpass2_init(&allpass, early_allpass_alloc_size, early_allpass_alloc_size,
                            ms_to_samples_frac(early_times_outer[index], plugin.samplerate), 
                            ms_to_samples_frac(early_times_inner[index], plugin.samplerate),
                            early_gains_outer[index],
                            early_gains_inner[index],
                            allocator)
        }
        
        fdn_max_delay := ms_to_samples(300.0 * parameter_infos[.ReverbSize].max, plugin.samplerate)
        
        init_feedback := reverb_compute_feedback(plugin.audio_param_values[.ReverbDecay], fdn_delays_ms[FDN_ORDER-1])
        ramped_value_init(&reverb.late.feedback, init_feedback, 0, allocator)
                          
        
        for channel in 0..<len(reverb.late.lfos) {
            frequency := 0.5 + 0.1*f32(channel)/f32(len(reverb.late.lfos))
            lfo_init(&reverb.late.lfos[channel], frequency, plugin.samplerate, max_buffer_size, allocator)        
        }
        
        for channel in 0..<len(reverb.late.delay_lines) {
            reverb.late.delay_lines[channel].buffer = make([]f32, fdn_max_delay, allocator)
            slice.zero(reverb.late.delay_lines[channel].buffer)
            
            // reverb.late.delay_frac[channel] = ms_to_samples_frac(fdn_delays_ms[channel], plugin.samplerate)
            delay_time := ms_to_samples_frac(fdn_delays_ms[channel] * plugin.audio_param_values[.ReverbSize], plugin.samplerate)
            ramped_value_init(&reverb.late.delays_frac[channel], delay_time, 0, allocator)
            
            make_lowpass1(&reverb.late.lp_filters[channel], plugin.audio_param_values[.ReverbTone], plugin.samplerate)
        }
        
        mem.zero(&reverb.late.lp_state, len(&reverb.late.lp_state) * len(&reverb.late.lp_state[0]) * size_of(f32))
        
        reverb.input_buffer = make([]f32, max_buffer_size, allocator)
        slice.zero(reverb.input_buffer)
        
        reverb.early_stage_buffer = make([]f32, max_buffer_size, allocator)
        slice.zero(reverb.early_stage_buffer)
        
        reverb.output_buffers[0] = make([]f32, max_buffer_size, allocator)
        reverb.output_buffers[1] = make([]f32, max_buffer_size, allocator)
        slice.zero(reverb.output_buffers[0])
        slice.zero(reverb.output_buffers[1])
        
        reverb.mix = plugin.audio_param_values[.ReverbMix]
    }
        
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
    }
}

handle_parameter_change :: proc(plugin: ^PluginData, param_index: ParamIDs, value: f32) {
    plugin.audio_param_values[param_index] = value

    switch param_index {
        case .InGain: {
            ramped_value_new_target(&plugin.input_gain, dbtoa(value), plugin.samplerate)
        }
        case .OutGain: {
            ramped_value_new_target(&plugin.output_gain, dbtoa(value), plugin.samplerate)
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
        
            mod_max : f32 : 100.0
            plugin.echo.mod_amount = value * mod_max
        }
        case .EchoMix: {
            ramped_value_new_target(&plugin.echo.mix, value, plugin.samplerate)
        }
        
        case .ReverbDecay: {
            max_delay_time := samples_to_ms(plugin.reverb.late.delays_frac[FDN_ORDER-1].target, plugin.samplerate)
            new_feedback := reverb_compute_feedback(plugin.audio_param_values[.ReverbDecay], max_delay_time)
                                                    
            ramped_value_new_target(&plugin.reverb.late.feedback, new_feedback, plugin.samplerate)
        }
        case .ReverbSize: {
        
            new_size := plugin.audio_param_values[.ReverbSize]
                        
            for &delay_frac, index in plugin.reverb.late.delays_frac {
                delay_time := ms_to_samples_frac(fdn_delays_ms[index] * new_size, plugin.samplerate)
                ramped_value_new_target(&delay_frac, delay_time, plugin.samplerate)
            }

            max_delay_time := samples_to_ms(plugin.reverb.late.delays_frac[FDN_ORDER-1].target, plugin.samplerate)
            new_feedback := reverb_compute_feedback(plugin.audio_param_values[.ReverbDecay], max_delay_time)
            
            ramped_value_new_target(&plugin.reverb.late.feedback, new_feedback, plugin.samplerate)
            
        }
        case .ReverbEarlyDiffusion: {}
        case .ReverbLateDiffusion: {}
        case .ReverbTone: {
            for &filter in plugin.reverb.late.lp_filters {
                make_lowpass1(&filter, value, plugin.samplerate)
            }
        }
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

plugin_sync_audio_to_main :: proc(plugin: ^PluginData) {
    for param_id, _ in ParamIDs {
        plugin.main_param_values[param_id] = plugin.audio_param_values[param_id]
    }
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
            
            
            ramped_value_fill_buffer(&plugin.input_gain, nsamples)
            ramped_value_fill_buffer(&plugin.output_gain, nsamples)
            
            for &sample, index in inputL { sample *= plugin.input_gain.value_buffer[index] }
            for &sample, index in inputR { sample *= plugin.input_gain.value_buffer[index] }
            
            
            echo_process(&plugin.echo, inputL, inputR)
            
            reverb_process(&plugin.reverb, inputL, inputR)
            
            for index in 0..<len(inputL) {
                inputL[index] = clamp(inputL[index], -1.0, 1.0)
                inputR[index] = clamp(inputR[index], -1.0, 1.0)
            }

            for &sample, index in inputL { sample *= plugin.output_gain.value_buffer[index] }
            for &sample, index in inputR { sample *= plugin.output_gain.value_buffer[index] }
            
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

@(export, rodata)
clap_entry := clap.Plugin_Entry {
    clap_version = clap.CLAP_VERSION,

    init = proc "c" (path: cstring) -> bool {
        context = runtime.default_context()
    
        plugin_descriptor.clap_version = clap.CLAP_VERSION
        plugin_descriptor.id           = PLUGIN_DESC_ID
        plugin_descriptor.name         = PLUGIN_NAME
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
    },

    deinit = proc "c" () {
        context = runtime.default_context()
        delete(plugin_features)
    },

    get_factory = proc "c" (id: cstring) -> rawptr {
        return id == clap.PLUGIN_FACTORY_ID ? &plugin_factory : nil
    },
}
