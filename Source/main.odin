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
import "core:c"
import opengl "vendor:OpenGL"

import imgui "../libs/odin-imgui"
// import imgui_win32 "../odin-imgui/imgui_impl_win32"
import imgui_opengl "../libs/odin-imgui/imgui_impl_opengl3"
import pugl "../libs/pugl-odin"

import cplug "../libs/cplug-odin"

when ODIN_DEBUG {
    when ODIN_OPTIMIZATION_MODE == .None {
        BUILD_CONFIG :: "debug"
    } else {
        BUILD_CONFIG :: "release_debug"
    }
} else {
    BUILD_CONFIG :: "release"
}

PLUGIN_DESC_ID :: "fdn_seeker.clap_ambient_" + BUILD_CONFIG
PLUGIN_NAME    :: "Clap Ambient " + BUILD_CONFIG

// une interface avec des nodes qui représentent les effets -> github.com/Nelarius/imnodes
// on peut drag les effets dans 3 ou 4 colonnes pour donner l'ordre (on peut mettre en parallele)
// chaque node peut etre configuré sur n'importe quel effet et l'interface s'affiche dans le node
// effets : delay, delay multitap, granulaire temps réel, reverb(s), looper habit chelou ?
// pourquoi pas dans le fond afficher le spectre de sortie ou une animation rigolote (apprendre opengl imagine)


ParamIDs :: enum u32 {
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
    format_string: string,
    min: f32,
    max: f32,
    default_value: f32,
    imgui_flags: imgui.SliderFlags,
}

parameter_infos := [ParamIDs]ParamInfo {
    .InGain = {
        name = "In Gain", format_string = "%.2f dB", min = -60.0, max = 6.0, default_value = 0.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
    },
    .OutGain = {
        name = "Out Gain", format_string = "%.2f dB", min = -60.0, max = 6.0, default_value = 0.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
    },

    .EchoTime = {
        name = "Delay Time", format_string = "%.2f ms", min = 1.0, max = 2000.0, default_value = 300.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
    },
    .EchoFeedback = {
        name = "Feedback", format_string = "%.2f %%", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
    },
    .EchoTone = {
        name = "Echo tone", format_string = "%.2f Hz", min = 500.0, max = 20000.0, default_value = 20000.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange, .Logarithmic},
    },
    .EchoModFreq = {
        name = "Echo mod freq", format_string = "%.2f Hz", min = 0.0, max = 10.0, default_value = 1.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
    },
    .EchoModAmount = {
        name = "Echo mod amount", format_string = "%.2f", min = 0.0, max = 1.0, default_value = 0.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
    },
    .EchoMix = {
        name = "Mix", format_string = "%.2f", min = 0.0, max = 1.0, default_value = 0.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
    },

    .ReverbDecay = {
        name = "Reverb decay", format_string = "%.2f%%", min = 0.0, max = 100.0, default_value = 5.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
    },
    .ReverbSize = {
        name = "Reverb size", format_string = "%.2f", min = 1.0, max = 5.0, default_value = 1.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
    },
    .ReverbEarlyDiffusion = {
        name = "Reverb Early Diffusion", format_string = "%.2f", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
    },
    .ReverbLateDiffusion = {
        name = "Reverb Late Diffusion", format_string = "%.2f", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
    },
    .ReverbTone = {
        name = "Reverb Tone", format_string = "%.2f", min = 200.0, max = 20000.0, default_value = 15000.0,
        imgui_flags = {.ClampOnInput, .ClampZeroRange, .Logarithmic},
    },
    .ReverbMix = {
        name = "Reverb mix", format_string = "%.2f", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = {.ClampOnInput, .ClampZeroRange},
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

// dest += source
add_buffers :: #force_inline proc(dest, source: []f32) {
    assert(len(dest) == len(source))

    for &sample, index in dest {
        sample += source[index]
    }
}

// dest += gain*source
add_buffers_with_gain_linear :: #force_inline proc(dest, source: []f32, gain: f32) {
    assert(len(dest) == len(source))

    for &sample, index in dest {
        sample += gain*source[index]
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


// ParamEventType :: enum {
//     GUI_VALUE_CHANGE,
//     GUI_GESTURE_BEGIN,
//     GUI_GESTURE_END,
// }

// ParamEvent :: struct {
//     param_index: ParamIDs,
//     event_type: ParamEventType,
//     value: f32,
// }

FIFO_SIZE :: 256
EventFIFO :: struct {
    events: [FIFO_SIZE]cplug.Event,
    write_index: u32,
    read_index: u32
}

main_push_event_to_audio :: proc(plugin: ^PluginData, param_index: ParamIDs, event_type: cplug.Event_Flag, value: f32) {

    write_index := intrin.atomic_load(&plugin.main_to_audio_fifo.write_index)

    event: ^cplug.Event = &plugin.main_to_audio_fifo.events[write_index]
    event.parameter.id = u32(param_index)
    event.parameter.type = event_type
    event.parameter.value = f64(value)

    intrin.atomic_add(&plugin.main_to_audio_fifo.write_index, 1)
    intrin.atomic_and(&plugin.main_to_audio_fifo.write_index, FIFO_SIZE-1)
}

DelayLine :: struct {
    buffer: []f32,
    write_index: u32,
}

delay_line_process_buffer_lagrange :: proc(dl: ^DelayLine, in_buffer, out_buffer: []f32, delay_frac: f32) {

    for &out_sample, sample_index in out_buffer {

        read_index_frac := f64(dl.write_index) - f64(delay_frac)
        out_sample = delay_line_read_sample_lagrange(dl^, f32(read_index_frac))

        delay_line_push_sample(dl, in_buffer[sample_index])
    }
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

    assert(read_position >= 0.0)
    assert(read_position < f32(len(dl.buffer)))

    index1 := int(read_position)
    index2 := index1 + 1

    if index2 >= len(dl.buffer) { index2 -= len(dl.buffer) }

    interp_coeff := read_position - f32(index1)
    sample1 := dl.buffer[index1]
    sample2 := dl.buffer[index2]

    out_sample := math.lerp(sample1, sample2, interp_coeff)
    assert(!math.is_nan(out_sample))

    return out_sample
}

FDN_ORDER :: 8
@rodata fdn_delays_ms := [FDN_ORDER]f32{ 47.871395, 52.17798, 54.59097, 53.903305, 51.67211, 54.251995, 51.666626, 52.31113 }

@rodata hadamard4 := [4][4]f32 { { 1,   1,   1,   1},
                                 { 1,  -1,   1,  -1},
                                 { 1,   1,  -1,  -1},
                                 { 1,  -1,  -1,   1} }

@rodata hadamard8 := [8][8]f32 { { 1,   1,   1,   1,   1,   1,   1,   1 },
                                 { 1,  -1,   1,  -1,   1,  -1,   1,  -1 },
                                 { 1,   1,  -1,  -1,   1,   1,  -1,  -1 },
                                 { 1,  -1,  -1,   1,   1,  -1,  -1,   1 },
                                 { 1,   1,   1,   1,  -1,  -1,  -1,  -1 },
                                 { 1,  -1,   1,  -1,  -1,   1,  -1,   1 },
                                 { 1,   1,  -1,  -1,  -1,  -1,   1,   1 },
                                 { 1,  -1,  -1,   1,  -1,   1,   1,  -1 } }


// @TODO voir si y'a pas un moyen plus opti de l'écrire que des boucles naives
// utiliser la fonction add_buffers_with_gain_linear ?
hadamard4_mix_buffers :: proc(inputs, outputs: [4][]f32) {

    for out_buffer, out_index in outputs {
        slice.zero(out_buffer)

        for in_buffer, in_index in inputs {
            gain := hadamard4[out_index][in_index] * 0.5

            for &sample, index in out_buffer {
                sample += gain * in_buffer[index]
            }
        }
    }
}

/*
notes :
    essayer une boucle avec : 2AP -> 1DL -> 2AP -> 1DL répéter autant que voulu et boucler
    injecter le signal à la sortie d'un DL (à un seul endroit pour pas avoir trop de diffusion au début)
    extraire les signaux de sorties aux sorties des DL et les répartir gaiche/droite
    complexifier le signal d'entrée par qq AP en séries, ou un FIR avec des AP sur chaque tap (simule les réflexions d'une grande piece)
    une boucle comme ca est équivalente à un FDN avec une matrice de mix creuse, mais est moins couteuse (ne demande pas de multiplication matricielle O(N^2))
    
*/
Reverb :: struct {

    in_lp: Biquad,
    lp_state: [2]f32,

    in_hp: Biquad,
    hp_state: [2]f32,

    diffusors: [2]DiffusorStage,

    late: struct {
        delay_lines: [FDN_ORDER]DelayLine,
        delays_frac: [FDN_ORDER]RampedValue,

        allpasses: [FDN_ORDER]AllpassDelay,

        lp_filter: Biquad,
        lp_state: [FDN_ORDER][2]f32,

        lfos: [FDN_ORDER]LFO,
        feedback: RampedValue,
    },

    input_buffer: []f32,
    early_stage_buffer: []f32,
    output_buffers: [2][]f32,
    mix: f32,
}

DiffusorStage :: struct {
    delay_lines: [4]DelayLine,
    allpasses: [4]AllpassDelay,
    delays_frac: [4]f32,
}

//github.com/Signalsmith-Audio/reverb-example-code/blob/main/reverb-example-code.h
reverb_compute_feedback :: proc(rt60: f32, max_delay_ms: f32) -> f32 {
    loops_per_rt60 := rt60/(max_delay_ms * 0.001 * 1.5)
    db_per_cycle := -60.0/loops_per_rt60

    return math.pow(10.0, db_per_cycle*0.05)
}

reverb_process :: proc(reverb: ^Reverb, bufferL: []f32, bufferR: []f32) {

    nsamples := u32(len(bufferL))

    reverb_input_buf := reverb.input_buffer[:nsamples]
    reverb_early_buf := reverb.early_stage_buffer[:nsamples]
    output_bufferL   := reverb.output_buffers[0][:nsamples]
    output_bufferR   := reverb.output_buffers[1][:nsamples]


    diff_delay_outputs: [4][]f32 = { make([]f32, nsamples, context.temp_allocator),
                                     make([]f32, nsamples, context.temp_allocator),
                                     make([]f32, nsamples, context.temp_allocator),
                                     make([]f32, nsamples, context.temp_allocator) }

    diff_mix_outputs: [4][]f32 = { make([]f32, nsamples, context.temp_allocator),
                                   make([]f32, nsamples, context.temp_allocator),
                                   make([]f32, nsamples, context.temp_allocator),
                                   make([]f32, nsamples, context.temp_allocator) }

    diff_ap_outputs: [4][]f32 = { make([]f32, nsamples, context.temp_allocator),
                                  make([]f32, nsamples, context.temp_allocator),
                                  make([]f32, nsamples, context.temp_allocator),
                                  make([]f32, nsamples, context.temp_allocator) }

    { // early

        // @TODO changer pour 2 delays à deux taps, c'est plus simple
        // ca demandera d'écrire le process inline
        delay_line_process_buffer_lagrange(&reverb.diffusors[0].delay_lines[0], bufferL, diff_delay_outputs[0], reverb.diffusors[0].delays_frac[0])
        delay_line_process_buffer_lagrange(&reverb.diffusors[0].delay_lines[1], bufferR, diff_delay_outputs[1], reverb.diffusors[0].delays_frac[1])
        delay_line_process_buffer_lagrange(&reverb.diffusors[0].delay_lines[2], bufferL, diff_delay_outputs[2], reverb.diffusors[0].delays_frac[2])
        delay_line_process_buffer_lagrange(&reverb.diffusors[0].delay_lines[3], bufferR, diff_delay_outputs[3], reverb.diffusors[0].delays_frac[3])

        for &ap, index in reverb.diffusors[0].allpasses {
            allpass_process_buffer(&ap, diff_delay_outputs[index], diff_ap_outputs[index])
        }


        hadamard4_mix_buffers(diff_ap_outputs, diff_mix_outputs)



        for &dl, index in reverb.diffusors[1].delay_lines {
            delay_line_process_buffer_lagrange(&dl, diff_mix_outputs[index], diff_delay_outputs[index], reverb.diffusors[1].delays_frac[index])
        }

        hadamard4_mix_buffers(diff_delay_outputs, diff_mix_outputs)
    }

    slice.zero(output_bufferL)
    slice.zero(output_bufferR)

    add_buffers_with_gain_linear(output_bufferL, diff_mix_outputs[0], 0.25)
    add_buffers_with_gain_linear(output_bufferL, diff_mix_outputs[1], 0.25)
    add_buffers_with_gain_linear(output_bufferR, diff_mix_outputs[2], 0.25)
    add_buffers_with_gain_linear(output_bufferR, diff_mix_outputs[3], 0.25)

    { //late
    // screams SIMD
        mod_amount : f32 = 20.0
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

            fdn_ins: [4]f32 = {diff_mix_outputs[0][index],
                               diff_mix_outputs[1][index],
                               diff_mix_outputs[2][index],
                               diff_mix_outputs[3][index]}

            for channel in 0..<FDN_ORDER {
                read_index_frac := (f32(reverb.late.delay_lines[channel].write_index)
                                    - reverb.late.delays_frac[channel].current_value
                                    + reverb.late.lfos[channel].sin_buffer[index] * mod_amount)

                delay_outputs[channel] = delay_line_read_sample_lagrange(reverb.late.delay_lines[channel], read_index_frac)
            }

            output_bufferL[index] += delay_outputs[0]
            output_bufferR[index] += delay_outputs[1]

            slice.zero(mixing_outputs[:])

            mixing_gain : f32 : 0.35355339059327373
            for channel in 0..<FDN_ORDER {
                for matrix_index in 0..<FDN_ORDER {
                    mixing_outputs[channel] += delay_outputs[matrix_index]*hadamard8[channel][matrix_index]
                }
                mixing_outputs[channel] *= mixing_gain
            }

            for channel in 0..<FDN_ORDER {
                delay_in := biquad_process_sample(reverb.late.lp_filter, reverb.late.lp_state[channel][:], mixing_outputs[channel])

                delay_in *= feedback
                delay_in += fdn_ins[channel & 3]

                delay_line_push_sample(&reverb.late.delay_lines[channel], delay_in)
            }
        }
    }

    for index in 0..<nsamples {
        bufferL[index] = math.lerp(bufferL[index], output_bufferL[index], reverb.mix)
        bufferR[index] = math.lerp(bufferR[index], output_bufferR[index], reverb.mix)
    }

    apply_gain_linear(bufferL, 0.5)
    apply_gain_linear(bufferR, 0.5)
}


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

allpass_process_buffer :: proc(ap: ^AllpassDelay, in_buffer, out_buffer: []f32) {
    assert(len(in_buffer) == len(out_buffer))

    for &sample, index in out_buffer {
        sample = allpass_process_sample(ap, in_buffer[index])
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


allpass2_process_buffer :: proc(ap: ^AllpassDelay2, in_buffer, out_buffer: []f32) {
    assert(len(in_buffer) == len(out_buffer))

    for &sample, index in out_buffer {
        sample = allpass2_process_sample(ap, in_buffer[index])
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
    plugin: ^PluginData,
    
    world: ^pugl.World,
    view: ^pugl.View,
    timer_id: uintptr,
    imgui_context: ^imgui.Context,
    width, height: int,

    test_slider_value :f32,
    test_slider_value2 :f32,
}

PluginData :: struct {
    host_context: ^cplug.Host_Context,
    
    max_buffer_size: u32,
    samplerate: f32,

    main_param_values: [ParamIDs]f32,
    audio_param_values: [ParamIDs]f32,
    param_is_in_edit: [ParamIDs]bool,
    main_to_audio_fifo: EventFIFO,
    audio_to_main_fifo: EventFIFO,

    input_gain: RampedValue,
    output_gain: RampedValue,

    main_arena: vmem.Arena,
    echo_arena: vmem.Arena,
    echo: Echo,

    reverb_arena: vmem.Arena,
    reverb: Reverb,
    gui: GUI,
}




@(export, link_prefix = "cplug_")
libraryLoad :: proc "c" () {
    context = runtime.default_context()
}

@(export, link_prefix = "cplug_")
libraryUnload :: proc "c" () {
    context = runtime.default_context()
}

@(export, link_prefix = "cplug_")
createPlugin :: proc "c" (ctx: ^cplug.Host_Context) -> rawptr {
    context = runtime.default_context()

    plugin := new(PluginData)
    plugin.host_context = ctx

    for param_id, _ in ParamIDs {
        
        info := &parameter_infos[param_id]

        plugin.main_param_values[param_id] = f32(info.default_value)
        plugin.audio_param_values[param_id] = f32(info.default_value)
    }


    return plugin
}

@(export, link_prefix = "cplug_")
destroyPlugin :: proc "c" (ptr: rawptr) {
    plugin := transmute(^PluginData)ptr
    context = runtime.default_context()

    deactivate_plugin(plugin)

    free(plugin)
}

@(export, link_prefix = "cplug_")
getNumInputBusses :: proc "c" (rawptr) -> u32 { return 1 }

@(export, link_prefix = "cplug_")
getNumOutputBusses :: proc "c" (rawptr) -> u32 { return 1 }

@(export, link_prefix = "cplug_")
getInputBusChannelCount :: proc "c" (_: rawptr, bus_idx: u32) -> u32 { return 2}

@(export, link_prefix = "cplug_")
getOutputBusChannelCount :: proc "c" (_: rawptr, bus_idx: u32) -> u32 { return 2 }

// Copy UTF8 name to this buffer, including null terminating byte.
// NOTE: VST3 uses UTF16 strings with a max length of 128 characters. Cplug the handles UTF16<->UTF8 conversion
//       CLAP has a max length of 256 bytes, AUv2 no limit (mandatory CFString), both are UTF8


// trouver comment print les trucs lààà
@(export, link_prefix = "cplug_")
getInputBusName :: proc "c" (_: rawptr, idx: u32, buf: cstring, buflen: i32) {
    context = runtime.default_context()
    
    fmt.bprintf(transmute([]u8)string(buf), "Stereo Input")
}

@(export, link_prefix = "cplug_")
getOutputBusName :: proc "c" (_: rawptr, idx: u32, buf: cstring, buflen: i32) {
    context = runtime.default_context()
    fmt.bprintf(transmute([]u8)string(buf), "Stereo Output")
}

@(export, link_prefix = "cplug_")
getLatencyInSamples :: proc "c" (rawptr) -> u32 { return 0 }

@(export, link_prefix = "cplug_")
getTailInSamples :: proc "c" (rawptr) -> u32 { return 0 }

// frees all the memory of the plugin before deleting or reseting
deactivate_plugin :: proc(plugin: ^PluginData) {

    vmem.arena_destroy(&plugin.main_arena)

    vmem.arena_destroy(&plugin.echo_arena)
    plugin.echo.delay_lineL.buffer = nil
    plugin.echo.delay_lineR.buffer = nil

    vmem.arena_destroy(&plugin.reverb_arena)
}

@(export, link_prefix = "cplug_")
setSampleRateAndBlockSize :: proc "c" (ptr: rawptr, sampleRate: f64, max_buffer_size: u32) {
    context = runtime.default_context()
    
    plugin := transmute(^PluginData)ptr

    deactivate_plugin(plugin)

    plugin.samplerate = cast(f32)sampleRate
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
        // @TODO prendre en compte l'amplitude de la modulation dans l'allocation des buffers de delays
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

        reverb.diffusors[0].delays_frac[0] = ms_to_samples_frac(4.5317416, plugin.samplerate)
        reverb.diffusors[0].delays_frac[1] = ms_to_samples_frac(6.241636, plugin.samplerate)
        reverb.diffusors[0].delays_frac[2] = ms_to_samples_frac(9.245789, plugin.samplerate)
        reverb.diffusors[0].delays_frac[3] = ms_to_samples_frac(28.552198, plugin.samplerate)

        for &dl in reverb.diffusors[0].delay_lines {
            dl.buffer = make([]f32, ms_to_samples(30.0, plugin.samplerate), allocator)
        }

        allpass_init(&reverb.diffusors[0].allpasses[0], cast(u32)ms_to_samples(20.0, plugin.samplerate), ms_to_samples_frac(5.32, plugin.samplerate), 0.4, allocator)
        allpass_init(&reverb.diffusors[0].allpasses[1], cast(u32)ms_to_samples(20.0, plugin.samplerate), ms_to_samples_frac(9.13, plugin.samplerate), 0.4, allocator)
        allpass_init(&reverb.diffusors[0].allpasses[2], cast(u32)ms_to_samples(20.0, plugin.samplerate), ms_to_samples_frac(13.7, plugin.samplerate), 0.4, allocator)
        allpass_init(&reverb.diffusors[0].allpasses[3], cast(u32)ms_to_samples(20.0, plugin.samplerate), ms_to_samples_frac(17.9, plugin.samplerate), 0.4, allocator)



        reverb.diffusors[1].delays_frac[0] = ms_to_samples_frac(8.781754, plugin.samplerate)
        reverb.diffusors[1].delays_frac[1] = ms_to_samples_frac(15.445027, plugin.samplerate)
        reverb.diffusors[1].delays_frac[2] = ms_to_samples_frac(22.079914, plugin.samplerate)
        reverb.diffusors[1].delays_frac[3] = ms_to_samples_frac(47.052425, plugin.samplerate)

        for &dl in reverb.diffusors[1].delay_lines {
            dl.buffer = make([]f32, ms_to_samples(60.0, plugin.samplerate), allocator)
        }

        allpass_init(&reverb.diffusors[1].allpasses[0], cast(u32)ms_to_samples(40.0, plugin.samplerate), ms_to_samples_frac(11.52, plugin.samplerate), 0.4, allocator)
        allpass_init(&reverb.diffusors[1].allpasses[1], cast(u32)ms_to_samples(40.0, plugin.samplerate), ms_to_samples_frac(19.3, plugin.samplerate), 0.4, allocator)
        allpass_init(&reverb.diffusors[1].allpasses[2], cast(u32)ms_to_samples(40.0, plugin.samplerate), ms_to_samples_frac(25.7, plugin.samplerate), 0.4, allocator)
        allpass_init(&reverb.diffusors[1].allpasses[3], cast(u32)ms_to_samples(40.0, plugin.samplerate), ms_to_samples_frac(38.9, plugin.samplerate), 0.4, allocator)


        fdn_max_delay := ms_to_samples(300.0 * parameter_infos[.ReverbSize].max, plugin.samplerate)

        init_feedback := plugin.audio_param_values[.ReverbDecay]
        init_feedback = scale(init_feedback, parameter_infos[.ReverbDecay].min, parameter_infos[.ReverbDecay].max, 0.0, 1.0, 0.3)
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

        }
        make_lowpass1(&reverb.late.lp_filter, plugin.audio_param_values[.ReverbTone], plugin.samplerate)

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
}

@(export, link_prefix = "cplug_")
process :: proc "c" (userPlugin: rawptr, ctx: ^cplug.Process_Context) {
    context = runtime.default_context()
    plugin := transmute(^PluginData)userPlugin

    // sync main to audio thread and send events to cplug
    read_index := intrin.atomic_load(&plugin.main_to_audio_fifo.read_index)
    write_index := intrin.atomic_load(&plugin.main_to_audio_fifo.write_index)

    for read_index != write_index {
    
        event := &plugin.main_to_audio_fifo.events[read_index]
        
        if event.type == .PARAM_CHANGE_UPDATE {
            plugin.audio_param_values[ParamIDs(event.parameter.id)] = cast(f32)event.parameter.value
        }
        
        ctx->enqueueEvent(event, 0)
        
        read_index += 1
        read_index &= FIFO_SIZE-1
    }    
    intrin.atomic_store(&plugin.main_to_audio_fifo.read_index, read_index)


    event: cplug.Event
    current_frame: u32 = 0

    for ctx->dequeueEvent(&event, current_frame) {
        switch event.type {
            case .PARAM_CHANGE_UPDATE: {
                setParameterValue(plugin, event.parameter.id, event.parameter.value)
            }
            case .PROCESS_AUDIO: {
                // audio render
                nsamples : u32 = event.processAudio.endFrame - current_frame
    
                input_bus:  [^][^]f32 = ctx->getAudioInput(0)
                output_bus: [^][^]f32 = ctx->getAudioOutput(0)
                
                assert(input_bus != nil)
                assert(input_bus[0] != nil)
                assert(input_bus[1] != nil)
                
                assert(output_bus != nil)
                assert(output_bus[0] != nil)
                assert(output_bus[1] != nil)
    
                inputL : []f32 = input_bus[0][current_frame:][:nsamples]
                inputR : []f32 = input_bus[1][current_frame:][:nsamples]
    
                outputL : []f32 = output_bus[0][current_frame:][:nsamples]
                outputR : []f32 = output_bus[1][current_frame:][:nsamples]
    
        
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
                
                current_frame = event.processAudio.endFrame
            }
            case .UNHANDLED_EVENT: {} 
            case .MIDI: {}
            case .PARAM_CHANGE_BEGIN: {}
            case .PARAM_CHANGE_END: {}
            case: {}
        }
    }

    free_all(context.temp_allocator)
}

@(export, link_prefix = "cplug_")
getNumParameters :: proc "c" (rawptr) -> u32 { return len(ParamIDs) }

@(export, link_prefix = "cplug_")
getParameterID :: proc "c" (_: rawptr, paramIndex: u32) -> u32 { return paramIndex }

// CPLUG_FLAG_PARAMETER_
@(export, link_prefix = "cplug_")
getParameterFlags :: proc "c" (_: rawptr, paramId: u32) -> u32  {

    return cast(u32)cplug.Parameter_Flag.IS_AUTOMATABLE
}

@(export, link_prefix = "cplug_")
getParameterRange :: proc "c" (_: rawptr, paramId: u32, min: ^f64, max: ^f64) {
    
    min^ = cast(f64)parameter_infos[ParamIDs(paramId)].min
    max^ = cast(f64)parameter_infos[ParamIDs(paramId)].max
}

// NOTE: AUv2 supports a max length of 52 bytes, VST3 128, CLAP 256

@(export, link_prefix = "cplug_")
getParameterName :: proc "c" (_: rawptr, paramId: u32, buf: [^]u8, buflen: i32) {
    context = runtime.default_context()

    name := parameter_infos[ParamIDs(paramId)].name
    assert(len(name) < int(buflen))
    fmt.bprint(buf[:buflen], name)
}

@(export, link_prefix = "cplug_")
getParameterValue :: proc "c" (ptr: rawptr, paramId: u32) -> f64 {
    plugin := transmute(^PluginData)ptr
    
    return cast(f64)plugin.audio_param_values[ParamIDs(paramId)]
}

@(export, link_prefix = "cplug_")
getDefaultParameterValue :: proc "c" (_: rawptr, paramId: u32) -> f64 {
    return cast(f64)parameter_infos[ParamIDs(paramId)].default_value
}

// [hopefully audio thread] VST3 & AU only

@(export, link_prefix = "cplug_")
setParameterValue :: proc "c" (ptr: rawptr, paramId: u32, value: f64) {
    context = runtime.default_context()
    // gérer la FIFO vers le main thread
    handle_parameter_change(transmute(^PluginData)ptr, ParamIDs(paramId), f32(value))
}

// VST3 only

@(export, link_prefix = "cplug_")
denormaliseParameterValue :: proc "c" (_: rawptr, paramId: u32, value: f64) -> f64 {
    context = runtime.default_context()
    
    min := cast(f64)parameter_infos[ParamIDs(paramId)].min
    max := cast(f64)parameter_infos[ParamIDs(paramId)].max
    
    denorm_value := value * (max - min) + min
    
    denorm_value = clamp(denorm_value, min, max)
    return denorm_value
}

@(export, link_prefix = "cplug_")
normaliseParameterValue :: proc "c" (_: rawptr, paramId: u32, value: f64) -> f64 {
    context = runtime.default_context()
    
    min := cast(f64)parameter_infos[ParamIDs(paramId)].min
    max := cast(f64)parameter_infos[ParamIDs(paramId)].max
    
    norm_value := (value - min)/(max - min)
    norm_value = clamp(norm_value, 0.0, 1.0) 
    return norm_value
}

@(export, link_prefix = "cplug_")
parameterStringToValue :: proc "c" (_: rawptr, paramId: u32, str: cstring) -> f64 {
    context = runtime.default_context()

    in_string := string(str)
    out_value, _ := strconv.parse_f64(in_string)
    // arrondir si le parametre est entier ou flottant
    return out_value
}

@(export, link_prefix = "cplug_")
parameterValueToString :: proc "c" (_: rawptr, paramId: u32, buf: [^]u8, bufsize: i32, value: f64) {
    context = runtime.default_context()
        
    format_string := parameter_infos[cast(ParamIDs)paramId].format_string
    mem.zero(buf, int(bufsize) * size_of(u8))
    fmt.bprintf(buf[:bufsize], format_string, value)
}


// plugin_state_save :: proc "c" (_plugin: ^clap.Plugin, stream: ^clap.Output_Stream) -> bool {
//     plugin := transmute(^PluginData)_plugin.plugin_data

//     // sync les parametres avant de les sauvegarder

//     num_params_written := stream.write(stream, raw_data(&plugin.main_param_values), size_of(f32)*len(ParamIDs))
//     return u64(num_params_written) == size_of(f32) * len(ParamIDs)
// }

// plugin_state_load :: proc "c" (_plugin: ^clap.Plugin, stream: ^clap.Input_Stream) -> bool {
//     plugin := transmute(^PluginData)_plugin.plugin_data

//     num_params_read := stream.read(stream, raw_data(&plugin.main_param_values), size_of(f32) * len(ParamIDs))
//     success: bool = num_params_read == i64(size_of(f32)) * len(ParamIDs)
//     return success
// }

@(export, link_prefix = "cplug_")
saveState :: proc "c" (userPlugin: rawptr, stateCtx: rawptr, writeProc: cplug.Write_Proc) {}

@(export, link_prefix = "cplug_")
loadState :: proc "c" (userPlugin: rawptr, stateCtx: rawptr, readProc: cplug.Read_Proc) {}

// NOTE: For AUv2, your pointer MUST be castable to NSView. AUv2 hosts expect an NSView & you simply override methods
// This is the only CPLUG method used in AUv2 builds.

@(export, link_prefix = "cplug_")
createGUI :: proc "c" (ptr: rawptr) -> rawptr {
    context = runtime.default_context()

    plugin := transmute(^PluginData)ptr
    gui := &plugin.gui
    gui.plugin = plugin
    
    gui.width = 1200
    gui.height = 600
    
    gui.world = pugl.NewWorld(.MODULE, 0)
    pugl.SetWorldString(gui.world, .CLASS_NAME, PLUGIN_NAME)
    
    
    return gui
}

@(export, link_prefix = "cplug_")
destroyGUI :: proc "c" (userGUI: rawptr) {
    gui := transmute(^GUI)userGUI
    plugin := gui.plugin
    
    setVisible(gui, i32(false))

    pugl.FreeWorld(gui.world)
    gui.world = nil
}

// If not NULL, set your window/view as a child/subview. If NULL, remove from parent/superview.
// This is a good place to init/deinit your GFX and timer. Be prepared for this to be called multiple times with NULL

@(export, link_prefix = "cplug_")
setParent :: proc "c" (userGUI: rawptr, parent_window_handle: rawptr) {
    context = runtime.default_context()
    gui := transmute(^GUI)userGUI
    plugin := gui.plugin
    
    if parent_window_handle == nil { 
        if gui.view == nil { return }
        pugl.FreeView(gui.view) 
        gui.view = nil
        return 
    }
    
    gui.view = pugl.NewView(gui.world)
    result := pugl.SetParent(plugin.gui.view, cast(pugl.Native_View)parent_window_handle)
    assert(result == .SUCCESS)
}

// CLAP only. VST3 simply create/destroy your window.

@(export, link_prefix = "cplug_")
setVisible :: proc "c" (userGUI: rawptr, visible: i32) {
    context = runtime.default_context()
    gui := transmute(^GUI)userGUI
    plugin := gui.plugin

    if gui.view == nil { return }

    if bool(visible) {
    
        pugl.SetPositionHint(gui.view, .DEFAULT_POSITION, 0, 0)
        pugl.SetSizeHint(gui.view, .DEFAULT_SIZE, u32(gui.width), u32(gui.height))
        // pugl.SetViewHint(gui.view, .DOUBLE_BUFFER, 1)
        // pugl.SetViewHint(gui.view, .SWAP_INTERVAL, 1)
        pugl.SetViewHint(gui.view, .REFRESH_RATE, 60)
        pugl.SetBackend(gui.view, pugl.GlBackend())
        pugl.SetViewHint(gui.view, .CONTEXT_VERSION_MAJOR, 3)
        pugl.SetViewHint(gui.view, .CONTEXT_VERSION_MINOR, 2)
        pugl.SetViewHint(gui.view, .CONTEXT_PROFILE, cast(i32)pugl.View_Hint_Value.OPENGL_COMPATIBILITY_PROFILE)
        pugl.SetHandle(gui.view, plugin)
        
        pugl.SetViewHint(gui.view, .RESIZABLE, 1)
        
        pugl.SetEventFunc(gui.view, gui_procedure)
        
        result := pugl.Realize(gui.view)
        assert(result == nil)
        
        result = pugl.Show(gui.view, .RAISE) 
        assert(result == .SUCCESS)
        
        gui.timer_id = 1
        result = pugl.StartTimer(gui.view, gui.timer_id, 16 * 0.001)
        assert(result == .SUCCESS)

    } else {
        pugl.Hide(gui.view)
        pugl.StopTimer(gui.view, gui.timer_id)
    }
}

@(export, link_prefix = "cplug_")
setScaleFactor :: proc "c" (userGUI: rawptr, scale: f32) {}

@(export, link_prefix = "cplug_")
getSize :: proc "c" (userGUI: rawptr, width: ^u32, height: ^u32) {
    gui := transmute(^GUI)userGUI

    width^ = u32(gui.width)
    height^ = u32(gui.height) 
}

// Host is trying to resize, but giving you the chance to overwrite their size

@(export, link_prefix = "cplug_")
checkSize :: proc "c" (userGUI: rawptr, width: ^u32, height: ^u32) {
    getSize(userGUI, width, height)
}

@(export, link_prefix = "cplug_")
setSize :: proc "c" (userGUI: rawptr, width: u32, height: u32) -> bool {
    gui := transmute(^GUI)userGUI

    gui.width = int(width)
    gui.height = int(height)
    
    return true
}

make_hslider :: proc(plugin: ^PluginData, param_index: ParamIDs) {

    infos := &parameter_infos[param_index]
    // fuite mémoire potentielle, mettre en place l'allocateur temporaire dans la boucle de gui
    slider_has_changed := imgui.SliderFloat(strings.clone_to_cstring(infos.name),
                                            &plugin.main_param_values[param_index],
                                            infos.min, infos.max,
                                            strings.clone_to_cstring(infos.format_string),
                                            infos.imgui_flags)

    handle_widget_update(plugin, param_index, slider_has_changed)
}

make_vslider :: proc(plugin: ^PluginData, param_index: ParamIDs, size: imgui.Vec2) {
    infos := &parameter_infos[param_index]

    slider_has_changed := imgui.VSliderFloat(strings.clone_to_cstring(infos.name), size,
                                            &plugin.main_param_values[param_index],
                                            infos.min, infos.max,
                                            strings.clone_to_cstring(infos.format_string),
                                            infos.imgui_flags)

    handle_widget_update(plugin, param_index, slider_has_changed)
}

handle_widget_update :: proc(plugin: ^PluginData, param_index: ParamIDs, widget_has_changed: bool) {

    if widget_has_changed {
        if !plugin.param_is_in_edit[param_index] {
            plugin.param_is_in_edit[param_index] = true

            main_push_event_to_audio(plugin, param_index, .PARAM_CHANGE_BEGIN, plugin.main_param_values[param_index])
        }

        main_push_event_to_audio(plugin, param_index, .PARAM_CHANGE_UPDATE, plugin.main_param_values[param_index])
    } else {

        if plugin.param_is_in_edit[param_index] {
            plugin.param_is_in_edit[param_index] = false

            main_push_event_to_audio(plugin, param_index, .PARAM_CHANGE_END, plugin.main_param_values[param_index])
        }
    }
}

gui_procedure :: proc "c" (view: ^pugl.View, event: ^pugl.Event) -> pugl.Status {
    context = runtime.default_context()
    
    plugin := transmute(^PluginData)pugl.GetHandle(view)
    gui := &plugin.gui

    imgui.SetCurrentContext(gui.imgui_context)

    #partial switch event.type {
        case .CONFIGURE: {
            
            pugl.EnterContext(gui.view)
            opengl.Viewport(0, 0, cast(i32)event.configure.width, cast(i32)event.configure.height)
            pugl.LeaveContext(gui.view)
            pugl.ObscureView(gui.view)
        
        }
        case .REALIZE: {
            imgui.CHECKVERSION()
            imgui.SetCurrentContext(nil)
            gui.imgui_context = imgui.CreateContext()
            imgui.SetCurrentContext(gui.imgui_context)
            
            imgui_io := imgui.GetIO()
            imgui_io.ConfigFlags = { .NoKeyboard }
            imgui_io.DisplaySize.x = f32(gui.width)
            imgui_io.DisplaySize.y = f32(gui.height)
            imgui_io.IniFilename = nil
            imgui_io.LogFilename = nil
            
            imgui.StyleColorsDark()
            
            opengl.load_up_to(3, 2, win32.gl_set_proc_address)
            imgui_opengl.Init()
        }
        case .UNREALIZE: {

            imgui.SetCurrentContext(gui.imgui_context)
            imgui_opengl.Shutdown()
            imgui.DestroyContext()
            gui.imgui_context = nil
            imgui.SetCurrentContext(nil)
        }
        case .UPDATE: {
            pugl.ObscureView(gui.view)
        }
        case .EXPOSE: {
            // plugin_sync_audio_to_main(plugin)

            io := imgui.GetIO()
            imgui_opengl.NewFrame()
            imgui.NewFrame()

            viewport := imgui.GetMainViewport()
            // position := viewport.WorkPos
            size := viewport.WorkSize

            // imgui.PushItemWidth(int), imgui.PopItemWidth()
            {
                imgui.SetNextWindowPos({0, 0})
                imgui.SetNextWindowSize({size.x, size.y})

                open: bool = true
                imgui.Begin("Mainwindow", &open, {.NoCollapse, .NoResize})

                gain_window_size : f32 = 60.0
                imgui.BeginChild("Volumes", {500, gain_window_size})
                make_hslider(plugin, .InGain)
                // imgui.SameLine()
                make_hslider(plugin, .OutGain)
                imgui.EndChild()

                imgui.BeginChild("Echo", {size.x/2, size.y-gain_window_size})

                imgui.SeparatorText("Echo")
                make_hslider(plugin, .EchoTime)
                make_hslider(plugin, .EchoFeedback)
                make_hslider(plugin, .EchoTone)
                make_hslider(plugin, .EchoModFreq)
                make_hslider(plugin, .EchoModAmount)
                make_hslider(plugin, .EchoMix)

                imgui.EndChild()

                imgui.SameLine()

                imgui.BeginChild("Reverb", {size.x/2, size.y-gain_window_size})

                imgui.SeparatorText("Reverb")
                make_hslider(plugin, .ReverbDecay)
                make_hslider(plugin, .ReverbSize)
                // make_hslider(plugin, .ReverbEarlyDiffusion)
                // make_hslider(plugin, .ReverbLateDiffusion)
                make_hslider(plugin, .ReverbTone)
                make_hslider(plugin, .ReverbMix)

                if imgui.Button("PANIC!") {
                    for &dl in plugin.reverb.late.delay_lines {
                        slice.zero(dl.buffer)
                    }

                    for &dl in plugin.reverb.diffusors[0].delay_lines {
                        slice.zero(dl.buffer)
                    }

                    for &dl in plugin.reverb.diffusors[1].delay_lines {
                        slice.zero(dl.buffer)
                    }

                    for &ap in plugin.reverb.diffusors[0].allpasses {
                        slice.zero(ap.delay_line.buffer)
                    }

                }

                imgui.EndChild()
                imgui.End()
            }

            clear_color := imgui.Vec4 {0.45, 0.55, 0.6, 1.0}
            imgui.Render()
            
            expose_event := &event.expose

            opengl.Viewport(cast(i32)expose_event.x, cast(i32)expose_event.y, cast(i32)expose_event.width, cast(i32)expose_event.height)
            opengl.ClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w)
            opengl.Clear(opengl.COLOR_BUFFER_BIT)

            imgui_opengl.RenderDrawData(imgui.GetDrawData())

            imgui.SetCurrentContext(nil)
        }
        case .CLOSE: {}
        case .FOCUS_IN: {}
        case .FOCUS_OUT: {}
        case .KEY_PRESS: {}
        case .KEY_RELEASE: {}
        case .TEXT: {
            io := imgui.GetIO()
            imgui.IO_AddInputCharacter(io, event.text.character)
        }
        case .POINTER_IN: {}
        case .POINTER_OUT: {}
        
        // mouse click
        case .BUTTON_PRESS: {} fallthrough
        case .BUTTON_RELEASE: {
            
            io := imgui.GetIO()
            
            button: imgui.MouseButton
            button = imgui.MouseButton(event.button.button)
            
            is_pressed := event.type == .BUTTON_PRESS
            imgui.IO_AddMouseButtonEvent(io, i32(button), is_pressed)
        }
        case .MOTION: {
        
            io := imgui.GetIO()
        
        
            imgui.IO_AddMousePosEvent(io, cast(f32)event.motion.x, cast(f32)event.motion.y)
        }
        case .SCROLL: {}
        case .CLIENT: {}
        case .TIMER: {
        
            pugl.Update(gui.world, 0.0)
        }
        case .LOOP_ENTER: {}
        case .LOOP_LEAVE: {}
        case .DATA_OFFER: {}
        case .DATA: {}
        case: {}
    }

    return .SUCCESS
}


// process_event :: proc(plugin: ^PluginData, event: ^clap.Event_Header) {

//     if event.space_id == clap.CORE_EVENT_SPACE_ID && event.event_type == clap.EVENT_PARAM_VALUE {
//         param_event := transmute(^clap.Event_Param_Value)event
//         param_index := cast(ParamIDs)param_event.param_id

//         handle_parameter_change(plugin, param_index, f32(param_event.value))
//     }
// }

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
            // mauvais calcul du decay
            scaled_decay := scale(plugin.audio_param_values[.ReverbDecay],
                                  parameter_infos[.ReverbDecay].min, parameter_infos[.ReverbDecay].max,
                                  0.0, 1.0, 0.3)

            // max_delay_time := samples_to_ms(plugin.reverb.late.delays_frac[FDN_ORDER-1].target, plugin.samplerate)
            // new_feedback := reverb_compute_feedback(scaled_decay, max_delay_time)

            ramped_value_new_target(&plugin.reverb.late.feedback, scaled_decay, plugin.samplerate)
        }
        case .ReverbSize: {

            new_size := plugin.audio_param_values[.ReverbSize]

            for &delay_frac, index in plugin.reverb.late.delays_frac {
                delay_time := ms_to_samples_frac(fdn_delays_ms[index] * new_size, plugin.samplerate)
                ramped_value_new_target(&delay_frac, delay_time, plugin.samplerate)
            }

            scaled_decay := scale(plugin.audio_param_values[.ReverbDecay],
                                  parameter_infos[.ReverbDecay].min, parameter_infos[.ReverbDecay].max,
                                  0.0, 1.0, 0.3)

            // max_delay_time := samples_to_ms(plugin.reverb.late.delays_frac[FDN_ORDER-1].target, plugin.samplerate)
            // new_feedback := reverb_compute_feedback(scaled_decay, max_delay_time)

            ramped_value_new_target(&plugin.reverb.late.feedback, scaled_decay, plugin.samplerate)

        }
        case .ReverbEarlyDiffusion: {}
        case .ReverbLateDiffusion: {}
        case .ReverbTone: {
            make_lowpass1(&plugin.reverb.late.lp_filter, value, plugin.samplerate)
        }
        case .ReverbMix: {
            plugin.reverb.mix = value
        }
    }
}




