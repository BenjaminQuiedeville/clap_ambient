package implot


import "core:c"

when ODIN_OS == .Windows {
    foreign import lib {
        "implot.lib"
    }
} else {
    foreign import lib {
        "libimplot.a"
    }
}

_ :: lib 


Context :: struct {}

@(default_calling_convention="c")
foreign lib {

    CreateContext :: proc() -> ^Context ---
    DestroyContext :: proc(ctx: ^Context = nil) ---
    GetcurrentContext :: proc() -> ^Context ---
    SetCurrentContext :: proc(ctx: ^Context) ---
    
    BeginPlot :: proc(title_id: cstring, size: imgui.Vec2, flags: ImPlotFlags) -> bool ---
    EndPlot :: proc() ---

    SetupAxis :: proc(axis: i32, )

}
