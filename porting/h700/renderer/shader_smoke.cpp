// Compile and link NativeEE's production shader library in a real GLES context.
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl32.h>

#include <cstdio>
#include <initializer_list>
#include <utility>

#include "engine/render/backends/gl/gl_shader_library.h"
#include "engine/render/backends/gl/gl_uniform_cache.h"

namespace {

bool CheckEgl(EGLBoolean result, const char* operation) {
    if (result == EGL_TRUE) return true;
    std::fprintf(stderr, "[egl] %s failed (0x%04x)\n", operation, eglGetError());
    return false;
}

}  // namespace

int main() {
    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (display == EGL_NO_DISPLAY) {
        std::fprintf(stderr, "[egl] eglGetDisplay failed (0x%04x)\n", eglGetError());
        return 2;
    }

    EGLint egl_major = 0, egl_minor = 0;
    if (!CheckEgl(eglInitialize(display, &egl_major, &egl_minor), "eglInitialize")) return 2;
    if (!CheckEgl(eglBindAPI(EGL_OPENGL_ES_API), "eglBindAPI")) {
        eglTerminate(display);
        return 2;
    }

    const EGLint config_attrs[] = {
        EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT_KHR,
        EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8,
        EGL_NONE
    };
    EGLConfig config = nullptr;
    EGLint config_count = 0;
    if (!CheckEgl(eglChooseConfig(display, config_attrs, &config, 1, &config_count), "eglChooseConfig") ||
        config_count != 1) {
        std::fprintf(stderr, "[egl] no GLES 3 pbuffer configuration\n");
        eglTerminate(display);
        return 2;
    }

    const EGLint pbuffer_attrs[] = {EGL_WIDTH, 16, EGL_HEIGHT, 16, EGL_NONE};
    EGLSurface surface = eglCreatePbufferSurface(display, config, pbuffer_attrs);
    if (surface == EGL_NO_SURFACE) {
        std::fprintf(stderr, "[egl] eglCreatePbufferSurface failed (0x%04x)\n", eglGetError());
        eglTerminate(display);
        return 2;
    }

    const EGLint context_attrs[] = {
        EGL_CONTEXT_MAJOR_VERSION_KHR, 3,
        EGL_CONTEXT_MINOR_VERSION_KHR, 2,
        EGL_NONE
    };
    EGLContext context = eglCreateContext(display, config, EGL_NO_CONTEXT, context_attrs);
    if (context == EGL_NO_CONTEXT ||
        !CheckEgl(eglMakeCurrent(display, surface, surface, context), "eglMakeCurrent")) {
        if (context != EGL_NO_CONTEXT) eglDestroyContext(display, context);
        eglDestroySurface(display, surface);
        eglTerminate(display);
        return 2;
    }

    GLint gl_major = 0, gl_minor = 0;
    glGetIntegerv(GL_MAJOR_VERSION, &gl_major);
    glGetIntegerv(GL_MINOR_VERSION, &gl_minor);
    const GLubyte* vendor = glGetString(GL_VENDOR);
    const GLubyte* renderer = glGetString(GL_RENDERER);
    const GLubyte* version = glGetString(GL_VERSION);
    std::fprintf(stderr, "[GLES] EGL=%d.%d context=%d.%d vendor=%s renderer=%s version=%s\n",
                 egl_major, egl_minor, gl_major, gl_minor,
                 vendor ? reinterpret_cast<const char*>(vendor) : "?",
                 renderer ? reinterpret_cast<const char*>(renderer) : "?",
                 version ? reinterpret_cast<const char*>(version) : "?");

    if (gl_major < 3 || (gl_major == 3 && gl_minor < 2)) {
        std::fprintf(stderr, "[FAIL] renderer smoke requires GLES 3.2 or newer\n");
        eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroyContext(display, context);
        eglDestroySurface(display, surface);
        eglTerminate(display);
        return 3;
    }

    ps2r::render::GlUniformCache uniforms;
    ps2r::render::GlShaderLibrary shaders;
    const bool built = shaders.Build(uniforms);
    const std::initializer_list<std::pair<const char*, uint32_t>> programs = {
        {"PS2", shaders.Ps2Program()},
        {"scanout", shaders.ScanoutProgram()},
        {"scanout-dither", shaders.ScanoutDitherProgram()},
        {"stencil-strip", shaders.StencilStripProgram()},
        {"stencil-invert", shaders.StencilInvertProgram()},
        {"constant", shaders.ConstProgram()},
        {"opaque-mask", shaders.OpaqueMaskProgram()}
    };
    bool all_programs = true;
    for (const auto& item : programs) {
        std::fprintf(stderr, "[SHADER] %-16s program=%u status=%s\n",
                     item.first, item.second, item.second ? "linked" : "MISSING");
        all_programs = all_programs && item.second != 0;
    }
    const uint32_t fast_program = shaders.Ps2FastProgram();
    std::fprintf(stderr, "[SHADER] %-16s program=%u status=%s\n",
                 "ps2-fast", fast_program, fast_program ? "linked (optional)" : "not built (optional)");

    glFinish();
    const GLenum gl_error = glGetError();
    shaders.Destroy();
    eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    eglDestroyContext(display, context);
    eglDestroySurface(display, surface);
    eglTerminate(display);

    if (!built || !all_programs || gl_error != GL_NO_ERROR) {
        std::fprintf(stderr, "[FAIL] NativeEE shader library build=%s all-programs=%s GL-error=0x%04x\n",
                     built ? "true" : "false", all_programs ? "true" : "false", gl_error);
        return 4;
    }
    std::fprintf(stderr, "[RESULT] PASS: all required NativeEE production shader programs compiled and linked in GLES 3.2\n");
    return 0;
}
