package clap_ambient

import "core:math"
import "core:sys/windows"
import "core:mem"
import "core:c/libc"
import "base:runtime"
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
// effets : delay, granulaire, reverb, looper habit chelou ?
// pourquoi pas dans le fond afficher le spectre de sortie ou une animation rigolote (apprendre opengl imagine)


ParamIDs :: enum u32 {
    Decay,
    Tone, 
    Mix,
    NParams,
}

EventFIFO :: struct {}

GUI :: struct {}

Reverb :: struct {}

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

audio_port_extension := clap_ext.Plugin_Audio_Ports {
    count = get_audio_ports_count,
    get = get_audio_ports_info,
}

get_num_params :: proc "c" (plugin: ^clap.Plugin) -> u32 { return cast(u32)ParamIDs.NParams }

params_get_info :: proc "c" (plugin: ^clap.Plugin, param_index: u32, param_info: ^clap_ext.Param_Info) -> bool {
    if param_index >= cast(u32)ParamIDs.NParams { return false }
    
    mem.zero(param_info, size_of(param_info^))
    param_info.id = param_index 
    param_info.flags = .AUTOMATABLE
    param_info.min_value = 0.0
    param_info.max_value = 1.0
    param_info.default_value = 0.5
    // le nom
    
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
    param_index := cast(ParamIDs)param_id
    
    switch param_index {
        case .Decay: {
            libc.snprintf(out_buffer, cast(uint)out_buffer_capacity, "%d sec", value)
            return true
        }
        case .Tone: {
            libc.snprintf(out_buffer, cast(uint)out_buffer_capacity, "%d Hz", value)
            return true
        }
        case .Mix: {
            libc.snprintf(out_buffer, cast(uint)out_buffer_capacity, "%d", value)
            return true
        }
        case .NParams: {
            return false 
        }
    }
    return false
}

param_convert_text_to_value :: proc "c" (plugin: ^clap.Plugin, param_id: clap.Clap_Id, param_value_text: cstring, out_value: ^f64) -> bool { return false }

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
    plugin.samplerate = cast(f32)samplerate
    plugin.min_buffer_size = min_buffer_size
    plugin.max_buffer_size = max_buffer_size
    
    // init et alloue tous ce qui a besoin de la samplerate ou de la block size
    
    return true 
}

plugin_deactivate :: proc "c" (_plugin: ^clap.Plugin) {
    // desalloue tout ce a été alloué dans activate
}

plugin_start_processing :: proc "c" (_plugin: ^clap.Plugin) -> bool { return true }

plugin_stop_processing :: proc "c" (_plugin: ^clap.Plugin) {}

plugin_reset :: proc "c" (_plugin: ^clap.Plugin) {}

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
            
            // process event 
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
            
            
            for index in 0..<nsamples {
                outputL[index] = inputL[index]
                outputR[index] = inputR[index]
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

plugin_descriptor := clap.Plugin_Descriptor {
    clap_version = clap.CLAP_VERSION,
    id           = "hermes140.clap_ambient",
    name         = "Clap Ambient",
    vendor       = "Hermes140",
    url          = "",
    manual_url   = "",
    support_url  = "",
    version      = "0.1",
    description  = "",

    features = raw_data([]cstring {
        "audio-effect",
        "stereo",
        "reverb",
        "delay",
        nil,
    }),
}


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

@export lib_init :: proc "c" (path: cstring) -> bool { return true }
@export lib_deinit :: proc "c" () {}
@export lib_get_factory :: proc "c" (id: cstring) -> rawptr {
    return id == clap.PLUGIN_FACTORY_ID ? &plugin_factory : nil
}
