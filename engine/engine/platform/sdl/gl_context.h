// platform/sdl/gl_context.h -- GlContext: the SDL graphics context on a Window.
//
// Desktop targets request OpenGL 4.1 core. The explicit H700 profile requests
// OpenGL ES 3.2 and validates the version returned by the SDL video driver.
// The depth attribute is 32 bits on desktop (24 on Windows / GLES); the swap
// interval is 0 so the presenter can apply its own frame pacing policy.
#pragma once

namespace ps2r {
namespace platform {

class Window;

class GlContext {
public:
    GlContext() = default;
    ~GlContext();
    GlContext(const GlContext&) = delete;
    GlContext& operator=(const GlContext&) = delete;

    // Sets the SDL_GL_* attributes (called by Window::Create after video init).
    static void RequestAttributes();
    bool Create(Window& window);
    void Destroy();
    bool MakeCurrent(Window& window);
    void SetSwapInterval(int interval);
    bool IsCreated() const { return context_ != nullptr || vita_initialized_; }
    const char* Version() const { return version_; }
    const char* Renderer() const { return renderer_; }

private:
    void* context_ = nullptr;     // SDL_GLContext
    bool vita_initialized_ = false;   // the Vita: vitaGL owns the one context (no SDL_GLContext)
    const char* version_ = "";
    const char* renderer_ = "";
};

}  // namespace platform
}  // namespace ps2r
