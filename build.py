import os
import os.path
import sys

common_cpp_flags = " ".join([
    "/nologo /MP /W3 /WX- /diagnostics:column /EHsc",
    "/fp:precise /Zc:wchar_t /Zc:forScope /Zc:inline /std:c++20",
    "/external:W3 /Gd /TP /errorReport:queue"
])
 

def Print(message): print(message, file = sys.stdout, flush = True)

def run(command):
    Print(command)
    result = os.system(command)
    if result != 0:
        Print("Error during command execution, exiting")
        exit(-1)
    return

def build_plugin_code(debug: bool, optim: bool, config: str):
    
    flags = "-build-mode:object -vet-semicolon"
    if debug: flags += " -debug"
    if optim: flags += " -o:speed -target-features:\"avx2\""

    build_dir = f"build/{config}/odin_code"
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    command = f"odin build source -define:BUILD_CONFIG={config} -out:{build_dir}/plugin_code.obj {flags}"
    run(command)
    return

def build_imgui(debug: bool):
    
    imgui_temp_dir = "odin-imgui/temp"
    build_dir = "build/imgui/Debug"

    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    sources = " ".join([
        f"{imgui_temp_dir}/imgui.cpp",
        f"{imgui_temp_dir}/imgui_demo.cpp",
        f"{imgui_temp_dir}/imgui_draw.cpp",
        f"{imgui_temp_dir}/imgui_tables.cpp", 
        f"{imgui_temp_dir}/imgui_widgets.cpp",
        f"{imgui_temp_dir}/c_imgui.cpp",
        f"{imgui_temp_dir}/c_imgui_internal.cpp",
        f"{imgui_temp_dir}/imgui_impl_opengl3.cpp",
        # f"{imgui_temp_dir}/imgui_impl_win32.cpp",
    ])

    flags = "/MP /c"
    
    if debug: 
        flags += " /Zi"
    else:
        flags += " /O2 /Ob2 /arch:AVX2"
    
    compile_command = f"cl {flags} /DIMGUI_IMPL_API=extern\\\"C\\\" /Fo:{build_dir}/ /Fd:{build_dir}/imgui {sources}"
    run(compile_command)
    
    
    link_command = f"lib /out:imgui.lib {build_dir}/*.obj"
    run(link_command)
    
    return 


def build_pugl(debug, optim, config):
    os.chdir("libs/pugl-odin")
    os.system("python build.py")
    os.chdir("../..")
    return

def build_clap(debug: bool, optim: bool, config: str):

    flags = "-build-mode:dll -vet-semicolon"
    if debug: flags += " -debug"
    if optim: flags += " -o:speed"# -target-features:\"avx2\""

    build_dir = f"build"

    command = f"odin build source -define:BUILD_CONFIG={config} -out:{build_dir}/ambient.clap {flags}"
    run(command)    
    return


def build_vstsdk(debug: bool, optim: bool, config: str):

    build_dir = f"build/{config}/vstsdk"
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)
    else:
        return

    includes = " ".join([
        "/Ilibs/vst3sdk",
        "/Ilibs/vst3sdk/public.sdk",
        "/Ilibs/vst3sdk/pluginterfaces",
    ])

    flags = " ".join([
        "/nologo /MP /W3 /WX- /diagnostics:column /EHsc",
        "/fp:precise /Zc:wchar_t /Zc:forScope /Zc:inline /std:c++20",
        "/external:W3 /Gd /TP /errorReport:queue",
    ])

    if debug: flags += " /Zi"
    if debug and not optim: flags += " /RTC1 /MDd"
    if optim: flags += " /O2 /Ob2 /MD /arch:AVX2"

    defines = " ".join([
        "/D _MBCS",
        "/D WIN32",
        "/D _WINDOWS",
    ])

    if debug: defines += " /DDEVELOPMENT"
    if optim and not debug: defines += " /DRELEASE"


    sources = " ".join([
        "libs/vst3sdk/base/source/baseiids.cpp",
        "libs/vst3sdk/base/source/fbuffer.cpp",
        "libs/vst3sdk/base/source/fdebug.cpp",
        "libs/vst3sdk/base/source/fdynlib.cpp",
        "libs/vst3sdk/base/source/fobject.cpp",
        "libs/vst3sdk/base/source/fstreamer.cpp",
        "libs/vst3sdk/base/source/fstring.cpp",
        "libs/vst3sdk/base/source/timer.cpp",
        "libs/vst3sdk/base/source/updatehandler.cpp" ,
        "libs/vst3sdk/base/thread/source/fcondition.cpp",
        "libs/vst3sdk/base/thread/source/flock.cpp",
        "libs/vst3sdk/pluginterfaces/base/conststringtable.cpp",
        "libs/vst3sdk/pluginterfaces/base/coreiids.cpp",
        "libs/vst3sdk/pluginterfaces/base/funknown.cpp",
        "libs/vst3sdk/pluginterfaces/base/ustring.cpp",
        "libs/vst3sdk/public.sdk/source/common/commoniids.cpp",
        "libs/vst3sdk/public.sdk/source/common/memorystream.cpp",
        "libs/vst3sdk/public.sdk/source/common/openurl.cpp",
        "libs/vst3sdk/public.sdk/source/common/pluginview.cpp",
        "libs/vst3sdk/public.sdk/source/common/readfile.cpp",
        "libs/vst3sdk/public.sdk/source/common/systemclipboard_linux.cpp",
        "libs/vst3sdk/public.sdk/source/common/systemclipboard_win32.cpp",
        "libs/vst3sdk/public.sdk/source/common/threadchecker_linux.cpp",
        "libs/vst3sdk/public.sdk/source/common/threadchecker_win32.cpp",
        "libs/vst3sdk/public.sdk/source/main/dllmain.cpp",
        "libs/vst3sdk/public.sdk/source/main/pluginfactory.cpp",
        "libs/vst3sdk/public.sdk/source/main/moduleinit.cpp",
        "libs/vst3sdk/public.sdk/source/vst/vstinitiids.cpp",
        "libs/vst3sdk/public.sdk/source/vst/vstnoteexpressiontypes.cpp",
        "libs/vst3sdk/public.sdk/source/vst/vstsinglecomponenteffect.cpp",
        "libs/vst3sdk/public.sdk/source/vst/vstaudioeffect.cpp",
        "libs/vst3sdk/public.sdk/source/vst/vstcomponent.cpp",
        "libs/vst3sdk/public.sdk/source/vst/vstcomponentbase.cpp",
        "libs/vst3sdk/public.sdk/source/vst/vstbus.cpp",
        "libs/vst3sdk/public.sdk/source/vst/vstparameters.cpp",
        "libs/vst3sdk/public.sdk/source/vst/utility/stringconvert.cpp",
    ])

    compile_command = f"cl /c {flags} {defines} {includes} {sources} /Fo:{build_dir}/ /Fd:{build_dir}/vstsdk.pdb"
    Print("Compiling the vst3 sdk")
    run(compile_command)

    link_command = f"Lib.exe /OUT:build/{config}/base-sdk-vst3.lib /NOLOGO /MACHINE:X64 {build_dir}/*.obj"
    Print("Linking the vst3 sdk -> base-sdk-vst3.lib")
    run(link_command)
    
    Print("\n\n")
    
    return

def build_wrapper(debug: bool, optim: bool, config: str):

    build_dir = f"build/{config}/clap-wrapper"
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)
    else:
        return

    flags = " ".join([
        "/c /nologo /MP /W3 /WX- /diagnostics:column /fp:precise",
        "/EHsc /GS /Zc:wchar_t /Zc:forScope /Zc:inline /std:c++20",
        "/external:W3 /Gd /TP /errorReport:queue /utf-8 /Zc:__cplusplus /Zc:char8_t-",
    ])
    
    if debug: flags += " /Zi"
    if debug and not optim: flags += " /RTC1 /MDd"
    if optim: flags += " /O2 /Ob2 /MD /arch:AVX2"

    defines = " ".join([
        "/D _MBCS",
        "/D WIN32",
        "/D _WINDOWS",
        "/D WIN=1",
        "/D CLAP_WRAPPER_VERSION=\\\"0.12.1\\\"",
        "/D CLAP_SUPPORTS_ALL_NOTE_EXPRESSIONS=0",
        "/D CLAP_WRAPPER_BUILD_FOR_VST3=1",
    ])

    if debug: defines += " /D DEVELOPMENT"
    if optim and not debug: defines += " /D RELEASE"

    includes = " ".join([
        "/Ilibs/clap/include",
        "/Ilibs/clap-wrapper/include",
        "/Ilibs/clap-wrapper/libs/fmt",
        "/Ilibs/clap-wrapper/libs/psl",
        "/Ilibs/clap-wrapper/src",
        "/Ilibs/vst3sdk",
        "/Ilibs/vst3sdk/public.sdk",
        "/Ilibs/vst3sdk/pluginterfaces",
    ])

    sources = " ".join([
        "libs/clap-wrapper/src/clap_proxy.cpp",
        "libs/clap-wrapper/src/detail/shared/sha1.cpp",
        "libs/clap-wrapper/src/detail/clap/fsutil.cpp",
        "libs/clap-wrapper/src/detail/os/windows.cpp",
        "libs/clap-wrapper/src/wrapasvst3_entry.cpp",
        "libs/clap-wrapper/src/wrapasvst3.cpp",
        "libs/clap-wrapper/src/detail/vst3/parameter.cpp",
        "libs/clap-wrapper/src/detail/vst3/plugview.cpp",
        "libs/clap-wrapper/src/detail/vst3/process.cpp",
        "libs/clap-wrapper/src/detail/vst3/categories.cpp",
    ])

    compile_command = f"cl.exe {flags} {defines} {includes} {sources} /Fo:{build_dir}/ /Fd:{build_dir}/clap-wrapper.pdb"

    link_command = f"Lib.exe /OUT:build/{config}/clap-wrapper.lib /NOLOGO /MACHINE:X64 {build_dir}/*.obj"

    Print("Compiling the clap wrapper")
    run(compile_command)

    Print("Linking clap wrapper -> clap-wrapper.lib")
    run(link_command)
    Print("\n\n")

    return

def final_build(debug: bool, optim: bool, config: str):

    entry_point_build_dir = f"build/{config}/entry_point"
    if not os.path.exists(entry_point_build_dir):
        os.makedirs(entry_point_build_dir)

    flags = " ".join([
        "/c /nologo /MP /W3 /WX- /diagnostics:column",
        "/EHsc /GS /fp:precise /Zc:wchar_t /Zc:forScope /Zc:inline /std:c++20",
        "/external:W3 /Gd /TP /errorReport:queue /utf-8 /Zc:__cplusplus /Zc:char8_t-",
    ])

    if debug: flags += " /Zi"
    if not optim: flags += " /RTC1 /MDd"
    if optim: flags += " /O2 /Ob2 /MD /arch:AVX2"

    defines = " ".join([
        "/D _WINDLL", "/D _MBCS", "/D WIN32","/D _WINDOWS", "/DWIN=1",
        "/D CLAP_WRAPPER_VERSION=\\\"0.12.1\\\"",
        "/D CLAP_WRAPPER_BUILD_FOR_VST3=1",
        "/D clap_ambient_vst3_EXPORTS",
        "/D CLAP_VST3_TUID_STRING=\\\"camb\\\"",
    ])

    if debug: defines += " /DDEVELOPMENT"
    if optim and not debug: defines += " /DRELEASE"

    includes = " ".join([
        "/I clap-wrapper/libs/psl",
        "/I../clap/include",
        "/Ilibs/vst3sdk",
        "/Ilibs/vst3sdk/public.sdk",
        "/Ilibs/vst3sdk/pluginterfaces",
        "/Iclap-wrapper/include",
        "/Iclap-wrapper/libs/fmt",
        "/Iclap-wrapper/src",
    ])

    sources = " ".join([
        "libs/clap-wrapper/src/wrapasvst3_export_entry.cpp",
    ])

    compile_command = f"cl.exe {flags} {defines} {includes} {sources} /Fo:{entry_point_build_dir}/ /Fd:{entry_point_build_dir}/entry_point.pdb"

    Print("\nEntry point compilation")
    run(compile_command)


    flags = " ".join([
        "/ERRORREPORT:QUEUE /NOLOGO",
        "/MANIFEST /MANIFESTUAC:\"level='asInvoker' uiAccess='false'\" /manifest:embed",
        "/SUBSYSTEM:CONSOLE",
        "/DYNAMICBASE:NO",
        "/MACHINE:X64 /DLL", 
    ])

    if optim: flags += " /OPT:REF"

    if debug: flags += " /DEBUG"

    wrapper_libs = " ".join([
        f"build/{config}/clap-wrapper.lib",
        f"build/{config}/base-sdk-vst3.lib",
    ])
    
    libs = " ".join([
        "opengl32.lib", "kernel32.lib", "shell32.lib", "gdi32.lib", "user32.lib",
        "ole32.lib", "oleaut32.lib", "uuid.lib", "dwmapi.lib", 
        "libs/odin-imgui/imgui_windows_x64.lib", "libs/pugl-odin/lib/pugl.lib"
    ])
    
    object_files = " ".join([
        f"{entry_point_build_dir}/*.obj",
    ])
    
    odin_object_files = " ".join([
        f"build/{config}/odin_code/*.obj",
    ])

    final_build_dir = f"build/{config}"
    out_name = f"{final_build_dir}/clap_ambient_{config}"
    
    Print("\nVST3 Linking")
    link_command = f"lld-link {flags} {object_files} {odin_object_files} {libs} {wrapper_libs} /OUT:{out_name}.vst3 /ILK:{out_name}_vst3.ilk /PDB:{out_name}_vst3.pdb /IMPLIB:{out_name}_vst3.lib"
    run(link_command)

    # Print("\nClap Linking")
    # link_clap_command = f"lld-link {flags} {odin_object_files} {libs} /OUT:{out_name}.clap /ILK:{out_name}_clap.ilk /PDB:{out_name}_clap.pdb /IMPLIB:{out_name}_vst3.lib"
    # run(link_clap_command)
    
    return


def main():
    
    argc = len(sys.argv)
    
    if argc == 1: 
        Print("Then call 'python build.py {debug|reldebug|release}' options to build the plugin")
        exit(0)

    debug = False
    optim = False
    config = sys.argv[1]

    if config == "debug":
        debug = True
    elif config == "reldebug":
        debug = True
        optim = True
        
    elif config == "release":
        optim = True
    
    elif config == "clean":
        os.system("rm -rf build")
        exit(0)    
    else:
        Print("Wrong config name")
        exit(0)


    if not os.path.exists(f"build/{config}"):
        os.makedirs(f"build/{config}")

    build_plugin_code(debug, optim, config)
    build_vstsdk(debug, optim, config)
    build_wrapper(debug, optim, config)
    build_pugl(debug, optim, config)
    # build_imgui(debug)
    final_build(debug, optim, config)
    # build_clap(debug, optim, config)
    Print("Done")
    return

if __name__ == "__main__":
    main()
