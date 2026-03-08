#ifndef PLUGIN_CONFIG_H
#define PLUGIN_CONFIG_H

#define CPLUG_IS_INSTRUMENT    0
#define CPLUG_WANT_GUI         1
#define CPLUG_GUI_RESIZABLE    1
#define CPLUG_WANT_MIDI_INPUT  0
#define CPLUG_WANT_MIDI_OUTPUT 0

#define CPLUG_COMPANY_NAME   "FDN_Seeker"
#define CPLUG_COMPANY_EMAIL  ""
#define CPLUG_PLUGIN_NAME    "Ambient"
#define CPLUG_PLUGIN_URI     ""
#define CPLUG_PLUGIN_VERSION "0.0.1"

// See list of categories here: https://steinbergmedia.github.io/vst3_doc/vstinterfaces/group__plugType.html
#define CPLUG_VST3_CATEGORIES "Fx|Stereo"

#define CPLUG_VST3_TUID_COMPONENT  'fdns', 'comp', 'xmpl', 0
#define CPLUG_VST3_TUID_CONTROLLER 'fdns', 'edit', 'xmpl', 0

// #define CPLUG_AUV2_VIEW_CLASS     CPLUGExampleView
// #define CPLUG_AUV2_VIEW_CLASS_STR "CPLUGExampleView"

#define CPLUG_CLAP_ID          "com.fdnseeker.ambient"
#define CPLUG_CLAP_DESCRIPTION "Ambient plugin"
#define CPLUG_CLAP_FEATURES    CLAP_PLUGIN_AUDIO_EFFECT, CLAP_PLUGIN_FEATURE_STEREO

#endif // PLUGIN_CONFIG_H
