import os
import os.path
import sys

def Print(message): print(message, file = sys.stdout, flush = True)

def run(command):
    Print(command)
    result = os.system(command)

    if result != 0:
        Print("Error during command execution, exiting")
        exit(-1)

    return


def build_plugin_code(debug: bool):
    # command = f"odin build source -out:build/plugin_code.lib -debug -pdb-name:build/plugin_code.pdb -build-mode:lib -vet-semicolon"
    command = f"odin build source -out:build/odin_code/plugin_code.obj -debug -build-mode:object -vet-semicolon"
    run(command)
    return


def build_clap(debug: bool):
    """
    --- building plugin entry and linking clap plugin
    C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\HostX64\x64\CL.exe
    /c /Zi/nologo /W3 /WX- /diagnostics:column /Od /Ob0
    /D _WINDLL /D _MBCS /D WIN32 /D _WINDOWS /D "CMAKE_INTDIR=\"Debug\"" /D clap_echo_clap_EXPORTS
    /EHsc /RTC1 /MD /GS /arch:AVX2 /fp:precise /Zc:wchar_t /Zc:forScope /Zc:inline /std:c++20
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


def build_vstsdk(debug: bool):

    build_dir = "build/vstsdk/Debug"
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    includes = " ".join([
        "/I../../libs/vst3sdk",
        "/I../../libs/vst3sdk/public.sdk",
        "/I../../libs/vst3sdk/pluginterfaces",
    ])

    flags = " ".join([
        "/c /Zi /nologo /MP /W3 /WX- /diagnostics:column /Od /Ob0",
        "/EHsc /RTC1 /MDd /GS /arch:AVX2",
        "/fp:precise /Zc:wchar_t /Zc:forScope /Zc:inline /std:c++20",
        "/external:W3 /Gd /TP /errorReport:queue",
    ])

    defines = " ".join([
        "/D _MBCS",
        "/D WIN32",
        "/D _WINDOWS",
        "/DDEVELOPMENT=1",
    ])

    sources = " ".join([
        "../../libs/vst3sdk/base/source/baseiids.cpp",
        "../../libs/vst3sdk/base/source/fbuffer.cpp",
        "../../libs/vst3sdk/base/source/fdebug.cpp",
        "../../libs/vst3sdk/base/source/fdynlib.cpp",
        "../../libs/vst3sdk/base/source/fobject.cpp",
        "../../libs/vst3sdk/base/source/fstreamer.cpp",
        "../../libs/vst3sdk/base/source/fstring.cpp",
        "../../libs/vst3sdk/base/source/timer.cpp",
        "../../libs/vst3sdk/base/source/updatehandler.cpp" ,
        "../../libs/vst3sdk/base/thread/source/fcondition.cpp",
        "../../libs/vst3sdk/base/thread/source/flock.cpp",
        "../../libs/vst3sdk/pluginterfaces/base/conststringtable.cpp",
        "../../libs/vst3sdk/pluginterfaces/base/coreiids.cpp",
        "../../libs/vst3sdk/pluginterfaces/base/funknown.cpp",
        "../../libs/vst3sdk/pluginterfaces/base/ustring.cpp",
        "../../libs/vst3sdk/public.sdk/source/common/commoniids.cpp",
        "../../libs/vst3sdk/public.sdk/source/common/memorystream.cpp",
        "../../libs/vst3sdk/public.sdk/source/common/openurl.cpp",
        "../../libs/vst3sdk/public.sdk/source/common/pluginview.cpp",
        "../../libs/vst3sdk/public.sdk/source/common/readfile.cpp",
        "../../libs/vst3sdk/public.sdk/source/common/systemclipboard_linux.cpp",
        "../../libs/vst3sdk/public.sdk/source/common/systemclipboard_win32.cpp",
        "../../libs/vst3sdk/public.sdk/source/common/threadchecker_linux.cpp",
        "../../libs/vst3sdk/public.sdk/source/common/threadchecker_win32.cpp",
        "../../libs/vst3sdk/public.sdk/source/main/dllmain.cpp",
        "../../libs/vst3sdk/public.sdk/source/main/pluginfactory.cpp",
        "../../libs/vst3sdk/public.sdk/source/main/moduleinit.cpp",
        "../../libs/vst3sdk/public.sdk/source/vst/vstinitiids.cpp",
        "../../libs/vst3sdk/public.sdk/source/vst/vstnoteexpressiontypes.cpp",
        "../../libs/vst3sdk/public.sdk/source/vst/vstsinglecomponenteffect.cpp",
        "../../libs/vst3sdk/public.sdk/source/vst/vstaudioeffect.cpp",
        "../../libs/vst3sdk/public.sdk/source/vst/vstcomponent.cpp",
        "../../libs/vst3sdk/public.sdk/source/vst/vstcomponentbase.cpp",
        "../../libs/vst3sdk/public.sdk/source/vst/vstbus.cpp",
        "../../libs/vst3sdk/public.sdk/source/vst/vstparameters.cpp",
        "../../libs/vst3sdk/public.sdk/source/vst/utility/stringconvert.cpp",
    ])

    compile_command = f"cl {flags} {defines} {includes} {sources} /Fo:{build_dir}/ /Fd:{build_dir}/vstsdk.pdb"

    link_command = f"Lib.exe /OUT:build/base-sdk-vst3.lib /NOLOGO /MACHINE:X64 /machine:x64 {build_dir}/*.obj"
    Print("Compiling the vst3 sdk")
    run(compile_command)
    Print("Linking the vst3 sdk -> base-sdk-vst3.lib")
    run(link_command)
    Print("\n\n")

    return


def build_wrapper(debug: bool):

    build_dir = "build/clap-wrapper/Debug"
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    flags = " ".join([
        "/c /Zi /nologo /MP /W3 /WX- /diagnostics:column",
        "/Od /Ob0 /arch:AVX2 /fp:precise",
        "/EHsc /RTC1 /MDd /GS /Zc:wchar_t /Zc:forScope /Zc:inline /std:c++20",
        "/external:W3 /Gd /TP /errorReport:queue /utf-8 /Zc:__cplusplus /Zc:char8_t-",
    ])

    defines = " ".join([
        "/D _MBCS",
        "/D WIN32",
        "/D _WINDOWS",
        "/D WIN=1",
        "/D CLAP_WRAPPER_VERSION=\\\"0.12.1\\\"",
        "/D CLAP_SUPPORTS_ALL_NOTE_EXPRESSIONS=0",
        "/D DEVELOPMENT=1",
        "/D CLAP_WRAPPER_BUILD_FOR_VST3=1",
    ])

    includes = " ".join([
        "/I../clap/include",
        "/Iclap-wrapper/include",
        "/Iclap-wrapper/libs/fmt",
        "/Iclap-wrapper/libs/psl",
        "/Iclap-wrapper/src",
        "/I../../libs/vst3sdk",
        "/I../../libs/vst3sdk/public.sdk",
        "/I../../libs/vst3sdk/pluginterfaces",
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

    Print("Compiling the clap wrapper")
    run(compile_command)

    link_command = f"Lib.exe /OUT:build/clap-wrapper.lib /NOLOGO /MACHINE:X64 /machine:x64 {build_dir}/*.obj"

    Print("Linking clap wrapper -> clap-wrapper.lib")
    run(link_command)
    Print("\n\n")

    return


def final_build(debug: bool):

    build_dir = "build/clap_ambient_vst3/Debug"
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    flags = " ".join([
        "/c /Zi /nologo /MP /W3 /WX- /diagnostics:column /Od /Ob0",
        "/EHsc /RTC1 /MDd /GS /arch:AVX2 /fp:precise /Zc:wchar_t /Zc:forScope /Zc:inline /std:c++20",
        "/external:W3 /Gd /TP /errorReport:queue /utf-8 /Zc:__cplusplus /Zc:char8_t-",
    ])

    defines = " ".join([
        "/D _WINDLL", "/D _MBCS", "/D WIN32","/D _WINDOWS", "/DWIN=1",
        "/D DEVELOPMENT=1",
        "/D CLAP_WRAPPER_VERSION=\\\"0.12.1\\\"",
        "/D CLAP_WRAPPER_BUILD_FOR_VST3=1",
        "/D clap_ambient_vst3_EXPORTS",
        "/D CLAP_VST3_TUID_STRING=\\\"camb\\\"",
    ])

    includes = " ".join([
        "/I clap-wrapper/libs/psl",
        "/I../clap/include",
        "/I../../libs/vst3sdk",
        "/I../../libs/vst3sdk/public.sdk",
        "/I../../libs/vst3sdk/pluginterfaces",
        "/Iclap-wrapper/include",
        "/Iclap-wrapper/libs/fmt",
        "/Iclap-wrapper/src",
    ])

    sources = " ".join([
        "clap-wrapper/src/wrapasvst3_export_entry.cpp",
    ])

    compile_command = f"cl.exe {flags} {defines} {includes} {sources} /Fo:{build_dir}/ /Fd:{build_dir}/vc143.pdb"

    Print("Entry point compilation")
    run(compile_command)


    flags = " ".join([
        "/ERRORREPORT:QUEUE /INCREMENTAL /NOLOGO",
        "/MANIFEST /MANIFESTUAC:\"level='asInvoker' uiAccess='false'\" /manifest:embed /DEBUG",
        "/SUBSYSTEM:CONSOLE /TLBID:1 /DYNAMICBASE /NXCOMPAT",
        "/MACHINE:X64  /machine:x64 /DLL",

    ])

    libs = " ".join([
        "build/clap-wrapper.lib",
        "build/base-sdk-vst3.lib",
        "opengl32.lib", "kernel32.lib", "user32.lib", "gdi32.lib",
        "winspool.lib", "shell32.lib", "ole32.lib", "oleaut32.lib",
        "uuid.lib", "comdlg32.lib", "advapi32.lib",
    ])
    
    object_files = " ".join([
        "build/clap_ambient_vst3/Debug/*.obj",
        "build/odin_code/*.obj",
    ])

    Print("Final Linking")
    link_command = f"link.exe {flags} {libs} /OUT:build/clap_ambient.vst3 /ILK:build/clap_ambient.ilk /PDB:build/clap_ambient.pdb /IMPLIB:build/clap_ambient_vst3.lib {object_files}"
    run(link_command)

    return


def main():

    if not os.path.exists("build"):
        os.mkdir("build")

    build_plugin_code(True)
    # build_vstsdk(True)
    # build_wrapper(True)
    final_build(True)

    Print("Done")
    return


main()
