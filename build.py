import os
import os.path
import sys


vst_sdk_dir = "../../libs/vst3sdk"

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
        f"{imgui_temp_dir}/imgui_impl_win32.cpp",
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

def build_clap(debug: bool):
    """
    --- building plugin entry and linking clap plugin
    C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\HostX64\x64\CL.exe
    /c /Zi/nologo /W3 /WX- /diagnostics:column /Od /Ob0
    /D _WINDLL /D _MBCS /D WIN32 /D _WINDOWS /D "CMAKE_INTDIR=\"Debug\"" /D clap_echo_clap_EXPORTS
    /EHsc /MD /GS /arch:AVX2 /fp:precise /Zc:wchar_t /Zc:forScope /Zc:inline /std:c++20 /RTC1
    /Fo"clap_echo_clap.dir\Debug\\" /Fd"clap_echo_clap.dir\Debug\vc143.pdb" /external:W3 /Gd /TP /errorReport:queue
    W:\clap\clap_echo\source\plugin_entry.cpp

    Link:
    C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\HostX64\x64\link.exe
    /ERRORREPORT:QUEUE /OUT:"W:\clap\clap_echo\build_msvc\CLAP\Debug\clap_echo.clap" /INCREMENTAL /ILK:"clap_echo_clap.dir\Debug\clap_echo.ilk"
    /NOLOGO
    Debug\clap_echo_static.lib
    opengl32.lib kernel32.lib user32.lib
    gdi32.lib winspool.lib shell32.lib
    ole32.lib oleaut32.lib uuid.lib
    comdlg32.lib advapi32.lib
    /MANIFEST /MANIFESTUAC:"level='asInvoker' uiAccess='false'"
    /manifest:embed /DEBUG /PDB:"C:/Users/benjamin/Dev/clap/clap_echo/build_msvc/CLAP/Debug/clap_echo.pdb"/SUBSYSTEM:CONSOLE
    /TLBID:1 /DYNAMICBASE /NXCOMPAT /IMPLIB:"C:/Users/benjamin/Dev/clap/clap_echo/build_msvc/Debug/clap_echo.lib"/MACHINE:X64
    /machine:x64 /DLL clap_echo_clap.dir\Debug\plugin_entry.obj
    """
    return


def build_vstsdk(debug: bool, optim: bool, config: str):

    build_dir = f"build/{config}/vstsdk"
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)
    else:
        return

    includes = " ".join([
        f"/I{vst_sdk_dir}",
        f"/I{vst_sdk_dir}/public.sdk",
        f"/I{vst_sdk_dir}/pluginterfaces",
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
        f"{vst_sdk_dir}/base/source/baseiids.cpp",
        f"{vst_sdk_dir}/base/source/fbuffer.cpp",
        f"{vst_sdk_dir}/base/source/fdebug.cpp",
        f"{vst_sdk_dir}/base/source/fdynlib.cpp",
        f"{vst_sdk_dir}/base/source/fobject.cpp",
        f"{vst_sdk_dir}/base/source/fstreamer.cpp",
        f"{vst_sdk_dir}/base/source/fstring.cpp",
        f"{vst_sdk_dir}/base/source/timer.cpp",
        f"{vst_sdk_dir}/base/source/updatehandler.cpp" ,
        f"{vst_sdk_dir}/base/thread/source/fcondition.cpp",
        f"{vst_sdk_dir}/base/thread/source/flock.cpp",
        f"{vst_sdk_dir}/pluginterfaces/base/conststringtable.cpp",
        f"{vst_sdk_dir}/pluginterfaces/base/coreiids.cpp",
        f"{vst_sdk_dir}/pluginterfaces/base/funknown.cpp",
        f"{vst_sdk_dir}/pluginterfaces/base/ustring.cpp",
        f"{vst_sdk_dir}/public.sdk/source/common/commoniids.cpp",
        f"{vst_sdk_dir}/public.sdk/source/common/memorystream.cpp",
        f"{vst_sdk_dir}/public.sdk/source/common/openurl.cpp",
        f"{vst_sdk_dir}/public.sdk/source/common/pluginview.cpp",
        f"{vst_sdk_dir}/public.sdk/source/common/readfile.cpp",
        f"{vst_sdk_dir}/public.sdk/source/common/systemclipboard_linux.cpp",
        f"{vst_sdk_dir}/public.sdk/source/common/systemclipboard_win32.cpp",
        f"{vst_sdk_dir}/public.sdk/source/common/threadchecker_linux.cpp",
        f"{vst_sdk_dir}/public.sdk/source/common/threadchecker_win32.cpp",
        f"{vst_sdk_dir}/public.sdk/source/main/dllmain.cpp",
        f"{vst_sdk_dir}/public.sdk/source/main/pluginfactory.cpp",
        f"{vst_sdk_dir}/public.sdk/source/main/moduleinit.cpp",
        f"{vst_sdk_dir}/public.sdk/source/vst/vstinitiids.cpp",
        f"{vst_sdk_dir}/public.sdk/source/vst/vstnoteexpressiontypes.cpp",
        f"{vst_sdk_dir}/public.sdk/source/vst/vstsinglecomponenteffect.cpp",
        f"{vst_sdk_dir}/public.sdk/source/vst/vstaudioeffect.cpp",
        f"{vst_sdk_dir}/public.sdk/source/vst/vstcomponent.cpp",
        f"{vst_sdk_dir}/public.sdk/source/vst/vstcomponentbase.cpp",
        f"{vst_sdk_dir}/public.sdk/source/vst/vstbus.cpp",
        f"{vst_sdk_dir}/public.sdk/source/vst/vstparameters.cpp",
        f"{vst_sdk_dir}/public.sdk/source/vst/utility/stringconvert.cpp",
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
        "/I../clap/include",
        "/Iclap-wrapper/include",
        "/Iclap-wrapper/libs/fmt",
        "/Iclap-wrapper/libs/psl",
        "/Iclap-wrapper/src",
        f"/I{vst_sdk_dir}",
        f"/I{vst_sdk_dir}/public.sdk",
        f"/I{vst_sdk_dir}/pluginterfaces",
    ])

    sources = " ".join([
        "clap-wrapper/src/clap_proxy.cpp",
        "clap-wrapper/src/detail/shared/sha1.cpp",
        "clap-wrapper/src/detail/clap/fsutil.cpp",
        "clap-wrapper/src/detail/os/windows.cpp",
        "clap-wrapper/src/wrapasvst3_entry.cpp",
        "clap-wrapper/src/wrapasvst3.cpp",
        "clap-wrapper/src/detail/vst3/parameter.cpp",
        "clap-wrapper/src/detail/vst3/plugview.cpp",
        "clap-wrapper/src/detail/vst3/process.cpp",
        "clap-wrapper/src/detail/vst3/categories.cpp",
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
        f"/I{vst_sdk_dir}",
        f"/I{vst_sdk_dir}/public.sdk",
        f"/I{vst_sdk_dir}/pluginterfaces",
        "/Iclap-wrapper/include",
        "/Iclap-wrapper/libs/fmt",
        "/Iclap-wrapper/src",
    ])

    sources = " ".join([
        "clap-wrapper/src/wrapasvst3_export_entry.cpp",
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

    libs = " ".join([
        f"build/{config}/clap-wrapper.lib",
        f"build/{config}/base-sdk-vst3.lib",
        "opengl32.lib", "kernel32.lib", "shell32.lib", "gdi32.lib", "user32.lib",
        "ole32.lib", "oleaut32.lib", "uuid.lib", 
        "imgui.lib",
    ])
    
    object_files = " ".join([
        f"{entry_point_build_dir}/*.obj",
        f"build/{config}/odin_code/*.obj",
    ])

    final_build_dir = f"build/{config}"
    out_name = f"{final_build_dir}/clap_ambient_{config}"
    
    Print("\nFinal Linking")
    link_command = f"lld-link {flags} {object_files} {libs} /OUT:{out_name}.vst3 /ILK:{out_name}.ilk /PDB:{out_name}.pdb /IMPLIB:{out_name}.lib"
    run(link_command)

    return


def main():
    
    argc = len(sys.argv)
    
    if argc == 1: 
        Print("First call 'python build.py deps' to build the dependencies")
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
    # build_imgui(debug)
    final_build(debug, optim, config)

    Print("Done")
    return

if __name__ == "__main__":
    main()
