package implot_test

import "core:fmt"
import "core:c"
import "core:strings"

import opengl "vendor:OpenGL"
import glfw "vendor:glfw"

import implot "../libs/implot-v1.0"
import imgui  "../libs/odin-imgui"
import imgui_opengl "../libs/odin-imgui/imgui_impl_opengl3"
import imgui_glfw "../libs/odin-imgui/imgui_impl_glfw"


main :: proc() {
    
    glfw.Init()
    defer glfw.Terminate()
    
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 2)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, 1) // i32(true)

    window := glfw.CreateWindow(1280, 720, "Implot test", nil, nil)
    assert(window != nil)
    defer glfw.DestroyWindow(window)

    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1) // vsync

    gl.load_up_to(3, 2, proc(p: rawptr, name: cstring) {
        (cast(^rawptr)p)^ = glfw.GetProcAddress(name)
    })

    imgui.CHECKVERSION()
    imgui.CreateContext()
    defer imgui.DestroyContext()
    io := imgui.GetIO()
    io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}

    imgui.StyleColorsDark()

    imgui_glfw.InitForOpenGL(window, true)
    defer imgui_glfw.Shutdown()
    imgui_opengl.Init("#version 150")
    defer imgui_opengl.Shutdown()

    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()

        imgui_opengl.NewFrame()
        imgui_glfw.NewFrame()
        imgui.NewFrame()

        imgui.ShowDemoWindow()

        if imgui.Begin("Window containing a quit button") {
            if imgui.Button("The quit button in question") {
                glfw.SetWindowShouldClose(window, true)
            }
        }
        imgui.End()

        imgui.Render()
        display_w, display_h := glfw.GetFramebufferSize(window)
        gl.Viewport(0, 0, display_w, display_h)
        gl.ClearColor(0, 0, 0, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT)
        imgui_opengl.RenderDrawData(imgui.GetDrawData())

        glfw.SwapBuffers(window)
    }
}
