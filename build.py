import os


# odin build command 
command = f"odin build source -out:clap_ambient_static.lib -debug -build-mode:lib -vet-semicolon"
print(command)
result = os.system(command)

if result != 0:
    exit(-1)

print(command)
command = "cmake --build build --config Debug"
result = os.system(command)

if result != 0:
    exit(-1)
