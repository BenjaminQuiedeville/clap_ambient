import os
import os.path
import sys
import shutil
import platform

OS = platform.system()

def Print(message): print(message, file = sys.stdout, flush = True)

def run(command):
    Print(command)
    result = os.system(command)
    if result != 0:
        Print("Error during command execution, exiting")
        exit(-1)
    return

# shutil.rmtree did not work on Windows
def remove_dir(path: str):
    Print(f"Removing directory \"{path}\"")
    if OS == "Windows": run("rmdir /S /Q build")
    else:               run("rm -rf build")

def build_plugin_code(debug: bool, optim: bool, config: str):

    build_dir = f"build/odin_code/{config}"
    os.makedirs(build_dir, exist_ok=True)

    flags = "-build-mode:object -reloc-mode:pic -vet-semicolon"
    if debug:
        flags += " -debug"

    if optim:
        flags += " -o:speed"

    if optim and OS in ["Windows", "Linux"]:
        flags += " -target-features:\"avx\""

    command = f"odin build Source -define:BUILD_CONFIG={config} -out:{build_dir}/plugin_code.obj {flags}"
    run(command)
    return


def get_imgui_libname() -> str:
    if OS == "Windows": return "imgui.lib"
    else:               return "libimgui.a"


def build_imgui():

    libname = get_imgui_libname()

    if os.path.exists(f"build/{libname}"): return

    os.chdir("libs/odin-imgui")
    run("python build.py")
    os.chdir("../..")

    shutil.copy(f"libs/odin-imgui/{libname}", f"build/{libname}")
    return


def get_pugl_libname() -> str:
    if OS == "Windows": return "pugl.lib"
    else:               return "libpugl.a"

def build_pugl():

    libname = get_pugl_libname()

    if os.path.exists(f"build/{libname}"): return

    os.chdir("libs/pugl-odin")
    run("python build.py")
    os.chdir("../..")

    shutil.copy(f"libs/pugl-odin/lib/{libname}", f"build/{libname}")
    return


def final_build(debug: bool, optim: bool, config: str):

    imgui_libname = get_imgui_libname()
    pugl_libname = get_pugl_libname()

    cmake_config = ""

    if debug and optim:
        cmake_config = "RelWithDebInfo"
    elif debug:
        cmake_config = "Debug"
    elif optim:
        cmake_config = "Release"
    else:
        print("Problème: debug et optim non spécifiés")
        exit(-1)

    odin_obj_dir = f"build/odin_code/{config}"

    run(f"cmake -S . -B build/cmake -G\"Ninja Multi-Config\" -DIMGUI_LIBNAME={imgui_libname} -DPUGL_LIBNAME={pugl_libname} -DODIN_OBJ_DIR={odin_obj_dir}")
    run(f"cmake --build build/cmake --config {cmake_config}")

    return


def main():

    argc = len(sys.argv)

    configs = ["debug", "reldebug", "release", "clean"]

    if argc == 1:
        Print(f"Call `python build.py 'config'` with config being one of {configs} to build the plugin")
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
        Print("Cleaning the build dir")
        remove_dir("build")
        exit(0)
    else:
        Print(f"Wrong config name, supported names are : {configs}")
        exit(0)

    build_plugin_code(debug, optim, config)
    build_pugl()
    build_imgui()
    final_build(debug, optim, config)
    Print("Done")
    return

if __name__ == "__main__":
    main()
