package clap_ambient

import "core:math"
import "core:sys/windows"
import "base:runtime"
import "vendor/directx/d3d11"
import "vendor/directx/dxgi"

import imgui "../odin-imgui"
import "../odin-imgui/imgui_impl_win32"
import "../odin-imgui/imgui_impl_dx11"
import "../clap-odin"

// une interface avec des nodes qui représentent les effets -> github.com/Nelarius/imnodes
// on peut drag les effets dans 3 ou 4 colonnes pour donner l'ordre (on peut mettre en parallele)
// chaque node peut etre configuré sur n'importe quel effet et l'interface s'affiche dans le node
// effets : delay, granulaire, reverb, looper habit chelou ?
// pourquoi pas dans le fond afficher le spectre de sortie ou une animation rigolote (apprendre opengl imagine)

ParamIDs :: enum {
    Decay,
    Tone, 
    Mix
    NParams,
}

EventFIFO :: struct {}

GUI :: struct {}

Reverb :: struct {}

PluginData :: struct {

    plugin: clap.plugin
    host: ^clap.host
    host_params: ^clap.host_params
    
    max_buffer_size: u32
    min_buffer_size: u32
    samplerate: f32
    
    main_param_values: [.NParams]f32
    audio_param_values: [.NParams]f32
    
    main_to_audio_fifo: EventFIFO

    reverb: Reverb
    gui: GUI
}

get_audio_ports_count :: proc "c" (plugin: ^clap.Plugin, is_input: bool) -> u32 { return 1 }

get_audio_ports_info :: proc "c" (plugin: ^clap.Plugin, index: u32, is_input: bool, info: ^clap.Audio_Port_Info) -> bool {
    // si y'a un probleme de canal audio faut revenir ici
    info.id = 0
    info.channel_count = 2
    info.flags = clap.AUDIO_PORT_IS_MAIN
    info.port_type = clap.PORT_STEREO
    info.in_place_pair = clap.INVALID_ID
    port_name :: "Main audio port"
    for charac, index in transmute([]u8)port_name {
        info.name[index] = charac
    }
}

audio_port_extension :: clap.Plugin_Audio_Ports {
    count = get_audio_ports_count,
    get = get_audio_ports_info,
};

get_num_params :: proc "c" (plugin: ^clap.Plugin) -> u32 { return cast(u32)ParamIDs.NParams }

params_get_info :: proc "c" (plugin: ^clap.Plugin, param_index: u32, param_info: ^clap.Param_Info) -> bool {}
param_get_value :: proc "c" (plugin: ^clap.Plugin, param_id: clap.Clap_Id, out_value: ^f64) -> bool {}
param_convert_value_to_text :: proc "c" (plugin: ^clap.Plugin, param_id: clap.Clap_Id, value: f64, out_buffer: [^]u8, out_buffer_capacity: u32) -> bool {}
param_convert_text_to_value :: proc "c" (plugin: ^clap.Plugin, param_id: clap.Clap_Id, param_value_text: cstring, out_value: ^f64) -> bool {}
param_flush :: proc "c" (plugin: ^clap.Plugin, in_events: ^clap.Input_Events, out_events: ^clap.Output_Events) {}

extensionParams :: clap.Plugin_Params {
    count = get_num_params,
    get_info = params_get_info,
    get_value = param_get_value,
    value_to_text = param_convert_value_to_text,
    text_to_value = param_convert_text_to_value,
    flush = param_flush
};


plugin_state_save :: proc "c" (_plugin: ^clap.Plugin, stream: ^clap.OStream) -> bool {
    plugin := transmute(^PluginData)_plugin.plugin_data
    
    // sync les parametres avant de les sauvegarder 
    
    num_params_written := stream.write(stream, plugin.main_param_values, sizeof(f32)*ParamIDs.NParams))
    return num_params_written == sizeof(f32) * ParamIDs.NParams
}

plugin_state_load :: proc "c" (plugin: ^clap.Plugin, stream: ^clap.IStream) -> bool {}

state_extension :: clap.Plugin_State {
    save = plugin_state_save,
    load = plugin_state_load,
};


is_gui_api_supported :: proc "c" (_plugin: ^clap.Plugin, api: cstring, id_floating: bool) -> bool {}
gui_get_preferred_api :: proc "c" (_plugin: ^clap.Plugin, api: ^cstring, is_floating: bool) -> bool {}
create_gui :: proc "c" (_plugin: ^clap.Plugin, api: cstring, is_floating: bool) -> bool {}
destroy_gui :: proc "c" (_plugin: ^clap.Plugin) {}
set_gui_scale :: proc "c" (_plugin: ^clap.Plugin, scale: f64) -> bool {}
get_gui_size :: proc "c" (_plugin: ^clap.Plugin, width, height: ^u32) -> bool {}
can_gui_resize :: proc "c" (_plugin: ^clap.Plugin) -> bool {}
get_gui_resize_hints :: proc "c" (_plugin: ^clap.Plugin, hints: ^clap.Gui_Resize_Hints) -> bool {}
adjust_gui_size :: proc "c" (_plugin: ^clap.Plugin, width, height: ^u32) -> bool {}
set_gui_size :: proc "c" (_plugin: ^clap.Plugin, width, height: u32) -> bool {}
set_gui_parent :: proc "c" (_plugin: ^clap.Plugin, window: ^clap.Window) -> bool {}
set_gui_transient :: proc "c" (_plugin: ^clap.Plugin, window: ^Window) -> bool {}
suggest_gui_title :: proc "c" (_plugin: ^clap.Plugin, title: cstring) {}
show_gui :: proc "c" (_plugin: ^clap.Plugin) -> bool,
hide_gui :: proc "c" (_plugin: ^clap.Plugin) -> bool,

gui_extension :: clap.Plugin_Gui {
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

    plugin.host_params = plugin.host.get_extension(plugin.host, clap.EXT_PARAMS)
    return true
}

plugin_destroy :: proc "c" (_plugin: ^clap.Plugin) {
    plugin := transmute(^PluginData)_plugin.plugin_data
}

plugin_activate :: proc "c" (_plugin: ^clap.Plugin, samplerate: f64, min_buffer_size: u32, max_buffer_size: u32) -> bool {}

plugin_deactivate :: proc "c" (_plugin: ^clap.Plugin) {}

plugin_start_processing :: proc "c" (_plugin: ^clap.Plugin) -> bool { return true }

plugin_stop_processing :: proc "c" (_plugin: ^clap.Plugin) {}

plugin_reset :: proc "c" (_plugin: ^clap.Plugin) {}

plugin_process :: proc "c" (_plugin: ^clap.Plugin, process: ^clap.Process) -> clap.Process_Status {}

plugin_get_extension :: proc "c" (_plugin: ^clap.Plugin, id: cstring) -> rawptr {}

plugin_on_main_thread :: proc "c" (_plugin: ^clap.Plugin) {}


clap_plugin :: clap.Plugin {
    desc             = &pluginDescriptor,
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

plugin_features : [^]cstring : {
    "audio-effect",
    "stereo",
    "reverb",
    "delay",
    nil,
};

plugin_descriptor :: clap.Plugin_Descriptor {
    clap_version = clap.CLAP_VERSION,
    id           = "hermes140.clap_ambient",
    name         = "Clap Ambient",
    vendor       = "Hermes140",
    url          = "",
    manual_url   = "",
    support_url  = "",
    version      = "0.1",
    description  = "",

    features = plugin_features,
};


get_plugin_count :: proc "c" (factory: ^clap.Plugin_Factory) -> u32 { return 1 }

get_plugin_descriptor :: proc "c" (factory: ^clap.Plugin_Factory, index: u32) -> ^clap.Plugin_Descriptor {
    return index == 0 ? &plugin_descriptor : nil
}

create_plugin :: proc "c" (factory: ^clap.Plugin_Factory, host: ^clap.Host, plugin_id: cstring) -> ^clap.Plugin {
    
    if plugin_id != descriptor.id {
        return nil
    }
    
    context = runtime.default_context()
    plugin := new(PluginData)
    plugin.host = host
    plugin.plugin = clap_plugin
    plugin.plugin.plugin_data = plugin
    
    return &plugin.plugin
}

plugin_factory :: clap.Plugin_Factory {
    get_plugin_count = get_plugin_count,
    get_plugin_descriptor = get_plugin_descriptor,
    create_plugin = create_plugin,
}


lib_init :: proc "c" (path: cstring) -> bool { return true }
lib_deinit :: proc "c" () {}
lib_get_factory :: proc "c" (id: cstring) -> rawptr {}
