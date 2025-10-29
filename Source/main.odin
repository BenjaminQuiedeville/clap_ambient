package clap_ambient

import "base:runtime"
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


ParamIDs :: enum u32 {
    Time,
    Feedback, 
    Mix,
    NParams,
}

ParamInfo :: struct {
    name: string,
    min: f32,
    max: f32,
    default_value: f32,
    imgui_flags: u32,
    clap_param_flags: clap_ext.Param_Info_Flag,
}

parameter_infos := [ParamIDs.NParams]ParamInfo {
    {
        name = "Delay Time", min = 1.0, max = 2000.0, default_value = 300.0,
        imgui_flags = 0,
        clap_param_flags = clap_ext.Param_Info_Flag.AUTOMATABLE
    },
    {
        name = "FeedBack", min = 0.0, max = 1.0, default_value = 0.5,
        imgui_flags = 0,
        clap_param_flags = clap_ext.Param_Info_Flag.AUTOMATABLE
    },
    {
        name = "Mix", min = 0.0, max = 1.0, default_value = 0.0,
        imgui_flags = 0,
        clap_param_flags = clap_ext.Param_Info_Flag.AUTOMATABLE
    },
}

RampedValue :: struct {
    target: f32,
    current_value: f32,
    step_height: f32,
    value_buffer: []f32,
}

ramped_value_init :: proc(value: ^RampedValue, init_value: f32, buffer_size: u32, arena: ^vmem.Arena) {

    value.target = init_value
    value.step_height = 0.0
    value.current_value = int_value
    value.value_buffer = make([]f32, buffer_size, vmem.arena_allocator(arena))
}

RAMP_TIME_MS : f32 : 100.0

ramped_value_new_target :: proc (value: ^RampedValue, new_target: f32, samplerate: f32) {
    value.target = new_target
    value.step_heigth = abs(value.current_value - new_target)/(RAMP_TIME_MS * 0.001 * samplerate)
}

ramped_value_step :: proc(value: ^RampedValue) -> f32 {
    
    if value.target == value.current_value {
        return value.current_value
    }

    distance = value.target - value.current_value
    
    if value.step_height >= abs(distance) {
        value.current_value = value.target
        return value.current_value
    }
    value.current_value += sign(distance)*value.step_heigth
    return value.current_value
}

ramped_value_fill_buffer :: proc(value: ^RampedValue, nsamples: u32) {
    
    for index in 0..<nsamples {
        value.value_buffer[index] = ramped_value.step(value)
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

GUI :: struct {}

Reverb :: struct {}

Echo :: struct {
    
    bufferL: []f32,
    bufferR: []f32,
    buffer_size: u32,
    write_index: u32,
    delay_frac: f32,
}

/*
objet Arena
arena_init_growing(Arena)
allocator = arena_allocator(^Arena)
*/

PluginData :: struct {        
    plugin: clap.Plugin,
    host: ^clap.Host,
    host_params: ^clap_ext.Host_Params,
    
    max_buffer_size: u32,
    min_buffer_size: u32,
    samplerate: f32,
    
    main_param_values: [ParamIDs.NParams]f32,
    audio_param_values: [ParamIDs.NParams]f32,
    
    main_to_audio_fifo: EventFIFO,

    main_arena: vmem.Arena,
    echo_arena: vmem.Arena,
    echo: Echo,
    reverb: Reverb,
    gui: GUI,
}


echo_set_delay :: proc(echo: ^Echo, delay_ms: f32, samplerate: f32) {
    delay_ms := clamp(delay_ms, parameter_infos[ParamIDs.Time].min, parameter_infos[ParamIDs.Time].max)
    echo.delay_frac = delay_ms * 0.001 * samplerate
}

echo_read_sample :: proc(buffer: []f32, read_position: f32) -> f32 {
    read_position := read_position

    if read_position < 0.0 { read_position += f32(len(buffer)) }
    
    read_index1 := int(read_position)
    read_index2 := read_index1 - 1
    
    if read_index2 < 0 { read_index2 += len(buffer) }
    
    interp_coeff := read_position - f32(read_index1)
    sample1 := buffer[read_index1]
    sample2 := buffer[read_index2]
    
    output_sample := math.lerp(sample1, sample2, interp_coeff)
    return output_sample
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


audio_port_extension := clap_ext.Plugin_Audio_Ports {
    count = get_audio_ports_count,
    get = get_audio_ports_info,
}

get_num_params :: proc "c" (plugin: ^clap.Plugin) -> u32 { return cast(u32)ParamIDs.NParams }

params_get_info :: proc "c" (plugin: ^clap.Plugin, param_index: u32, information: ^clap_ext.Param_Info) -> bool {
    if param_index >= cast(u32)ParamIDs.NParams { return false }
    
    mem.zero(information, size_of(information^))
    information.id = param_index 
    information.flags = parameter_infos[param_index].clap_param_flags
    information.min_value = f64(parameter_infos[param_index].min)
    information.max_value = f64(parameter_infos[param_index].max)
    information.default_value = f64(parameter_infos[param_index].default_value)
    
    name := parameter_infos[param_index].name
    for char_index in 0..<len(name) {
        information.name[char_index] = raw_data(name)[char_index]
    }
    
    return true
}

param_get_value :: proc "c" (_plugin: ^clap.Plugin, param_id: clap.Clap_Id, out_value: ^f64) -> bool {
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    param_index := cast(u32)param_id
    if param_index > cast(u32)ParamIDs.NParams { return false }
    
    out_value^ = cast(f64)plugin.audio_param_values[param_index]
    return true
}

param_convert_value_to_text :: proc "c" (plugin: ^clap.Plugin, param_id: clap.Clap_Id, value: f64, out_buffer: [^]u8, out_buffer_capacity: u32) -> bool {
    
    context = runtime.default_context()

    param_index := cast(ParamIDs)param_id
    
    out_string := strings.string_from_ptr(out_buffer, int(out_buffer_capacity))
    
    switch param_index {
        case .Time: {
            fmt.bprintf(transmute([]u8)out_string, "%d sec", value)
            return true
        }
        case .Feedback: {
            fmt.bprintf(transmute([]u8)out_string, "%d Hz", value)
            return true
        }
        case .Mix: {
            fmt.bprintf(transmute([]u8)out_string, "%d", value)
            return true
        }
        case .NParams: {
            return false 
        }
    }
    return false
}

param_convert_text_to_value :: proc "c" (plugin: ^clap.Plugin, param_id: clap.Clap_Id, param_value_text: cstring, out_value: ^f64) -> bool {
    context = runtime.default_context()

    in_string := string(param_value_text)
    out_value^ = strconv.atof(in_string)
    return false 
}

param_flush :: proc "c" (_plugin: ^clap.Plugin, in_events: ^clap.Input_Events, out_events: ^clap.Output_Events) {
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    event_count := in_events.size(in_events)
    // sync main to audio
    
    for event_index in 0..<event_count {
        // process_event 
    }
}


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
    
    num_params_written := stream.write(stream, raw_data(&plugin.main_param_values), size_of(f32)*cast(u64)ParamIDs.NParams)
    return u64(num_params_written) == size_of(f32) * u64(ParamIDs.NParams)
}

plugin_state_load :: proc "c" (_plugin: ^clap.Plugin, stream: ^clap.IStream) -> bool {
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    num_params_read := stream.read(stream, raw_data(&plugin.main_param_values), size_of(f32) * cast(u64)ParamIDs.NParams)
    success: bool = num_params_read == i64(size_of(f32)) * cast(i64)ParamIDs.NParams
    return success
}


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
    for param_id, param_index in ParamIDs {
        
        if param_id == .NParams { break }
    
        information: clap_ext.Param_Info
        
        params_get_info(_plugin, u32(param_index), &information)
        plugin.main_param_values[param_index] = f32(information.default_value)
        plugin.audio_param_values[param_index] = f32(information.default_value)
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
        
        // init les ramped values avec les buffers
        
    }
    
    {
        error := vmem.arena_init_growing(&plugin.echo_arena, 4 * mem.Megabyte)
        ensure(error == nil)
    
        allocator := vmem.arena_allocator(&plugin.echo_arena)
    
        echo := &plugin.echo
        echo.buffer_size = u32(parameter_infos[ParamIDs.Time].max * 0.001 * plugin.samplerate)
        echo.bufferL = make([]f32, echo.buffer_size, allocator)
        echo.bufferR = make([]f32, echo.buffer_size, allocator)
        
        echo.write_index = 0
        echo.delay_frac = 0
        
        echo_set_delay(echo, plugin.audio_param_values[ParamIDs.Time], plugin.samplerate)
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
    plugin.echo.bufferL = nil
    plugin.echo.bufferR = nil
}

plugin_start_processing :: proc "c" (_plugin: ^clap.Plugin) -> bool { return true }

plugin_stop_processing :: proc "c" (_plugin: ^clap.Plugin) {}

plugin_reset :: proc "c" (_plugin: ^clap.Plugin) {}

process_event :: proc(plugin: ^PluginData, event: ^clap.Event_Header) {
    
    if event.space_id == clap.CORE_EVENT_SPACE_ID && event.event_type == clap.Event_Type.PARAM_VALUE {
        param_event := transmute(^clap.Event_Param_Value)event
        
        plugin.audio_param_values[param_event.param_id] = f32(param_event.value)
    }
}

plugin_process :: proc "c" (_plugin: ^clap.Plugin, process: ^clap.Process) -> clap.Process_Status { 
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    // sync main to audio thread
    context = runtime.default_context()
    assert(process.audio_outputs_count == 1)
    assert(process.audio_inputs_count == 1)
    
    frame_count := process.frames_count 
    input_event_count := process.in_events.size(process.in_events)
    
    event_index : u32 = 0
    next_event_frame : u32 = input_event_count != 0 ? 0 : frame_count
    
    for current_frame_index : u32 = 0; current_frame_index < frame_count ; {
        for event_index < input_event_count && next_event_frame == current_frame_index {
            event: ^clap.Event_Header = process.in_events.get(process.in_events, event_index)
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
            
            echo := &plugin.echo
            
            for index in 0..<nsamples {
            
                // traiter les smooths params
                delay_ms := plugin.audio_param_values[ParamIDs.Time]  
                feedback := plugin.audio_param_values[ParamIDs.Feedback]
                mix := plugin.audio_param_values[ParamIDs.Mix]
                
                echo_set_delay(echo, delay_ms, plugin.samplerate)
                
                read_index_frac := f32(echo.write_index) - echo.delay_frac
                output_sampleL := echo_read_sample(echo.bufferL, read_index_frac)
                output_sampleR := echo_read_sample(echo.bufferR, read_index_frac)
                
                input_sampleL := inputL[index]
                input_sampleR := inputR[index]
                
                outputL[index] = math.lerp(output_sampleL, input_sampleL, mix)
                outputR[index] = math.lerp(output_sampleR, input_sampleR, mix)
                
                echo.bufferL[echo.write_index] = input_sampleL + output_sampleL * feedback
                echo.bufferR[echo.write_index] = input_sampleR + output_sampleR * feedback
                
                echo.write_index += 1
                if echo.write_index == echo.buffer_size { echo.write_index = 0 }
                
            }
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
