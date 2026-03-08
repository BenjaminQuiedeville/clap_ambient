import os
import os.path
import sys
import platform
 

OS = platform.system() # Linux, Darwin or Windows

def Print(message): print(message, file = sys.stdout, flush = True)

def run(command):
    Print(command)
    result = os.system(command)
    if result != 0:
        Print("Error during command execution, exiting")
        exit(-1)
    return

def build_plugin_code(debug: bool, optim: bool, config: str):

    print("\n-------- Building odin plugin code --------")
    
    flags = "-build-mode:object -vet-semicolon"
    if debug: flags += " -o:none -debug"
    if optim: 
        flags += " -o:speed"
        if OS != "Darwin":
            flags += " -target-features:\"avx2\""

    build_dir = f"build/{config}/odin_code"
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    command = f"odin build source -out:{build_dir}/plugin_code.obj {flags}"
    run(command)
    return

def build_imgui(debug: bool):

    if os.path.exists("libs/odin-imgui/imgui_windows_x64.lib"):
        return
    
    print("\n-------- Building imgui --------")
    os.chdir("libs/odin-imgui")
    os.system("python build.py")
    os.chdir("../..")
    
    return 


def build_pugl(debug, optim, config):

    if os.path.exists("libs/pugl-odin/lib/pugl.lib"):
        return
        
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


def final_build(debug: bool, optim: bool, config: str):

    flags = " ".join([
        "/NOLOGO",
        "/SUBSYSTEM:CONSOLE",
        "/MACHINE:X64 /DLL", 
    ])

    if optim: flags += " /OPT:REF"

    if debug: flags += " /DEBUG"
    
    libs = " ".join([
        "opengl32.lib", "gdi32.lib","dwmapi.lib",
        "libs/odin-imgui/imgui_windows_x64.lib", "libs/pugl-odin/lib/pugl.lib"
    ])
         
    object_files = " ".join([
        f"build/{config}/odin_code/*.obj",
        "libs/cplug-odin/cplug_vst3.o"
    ])

    final_build_dir = f"build/{config}"
    out_name = f"{final_build_dir}/clap_ambient_{config}"
    
    Print("\n-------- VST3 Linking -------- ")
    link_command = f"lld-link {flags} {object_files} {libs} /OUT:{out_name}.vst3 /ILK:{out_name}_vst3.ilk /PDB:{out_name}_vst3.pdb"
    run(link_command)
    
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
    build_pugl(debug, optim, config)
    build_imgui(debug)

    os.chdir("libs/cplug-odin")
    run("clang -c -g -gcodeview -D_WIN32 -D_CRT_SECURE_NO_WARNINGS -include ../../Source/config.h -I CPLUG/src CPLUG/src/cplug_vst3.c")
    os.chdir("../..")

    final_build(debug, optim, config)
    # build_clap(debug, optim, config)
    Print("Done")
    return

if __name__ == "__main__":
    main()
