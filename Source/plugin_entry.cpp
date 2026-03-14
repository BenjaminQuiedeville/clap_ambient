#include "../libs/clap/include/clap/entry.h"

extern "C" {
    const extern clap_plugin_entry_t odin_entry;
    CLAP_EXPORT extern const clap_plugin_entry_t clap_entry;
    const CLAP_EXPORT clap_plugin_entry_t clap_entry = odin_entry;
}
