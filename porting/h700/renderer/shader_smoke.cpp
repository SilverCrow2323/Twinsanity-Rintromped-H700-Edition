// Compile and link NativeEE's production shader library in a real GLES context.
// Include NativeEE's platform abstraction before EGL/GLES headers: some GLES
// platform headers expose macros whose names overlap the platform API types.
#include "engine/render/backends/gl/gl_shader_library.h"
#include "engine/render/backends/gl/gl_uniform_cache.h"

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl32.h>

#include <array>
#include <cstddef>
#include <cstdio>
#include <initializer_list>
#include <utility>

namespace {

bool CheckEgl(EGLBoolean result, const char* operation) {
    if (result == EGL_TRUE) return true;
    std::fprintf(stderr, "[egl] %s failed (0x%04x)\n", operation, eglGetError());
    return false;
}


bool ReadRgbaPixel(const char* stage, const std::array<GLubyte, 4>& expected) {
    std::array<GLubyte, 4> actual{};
    glReadPixels(8, 8, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, actual.data());
    const GLenum error = glGetError();
    bool matches = error == GL_NO_ERROR;
    for (std::size_t i = 0; i < actual.size(); ++i) {
        const int difference = static_cast<int>(actual[i]) - static_cast<int>(expected[i]);
        if (difference < -2 || difference > 2) matches = false;
    }
    std::fprintf(stderr,
                 "[TARGET] %-20s pixel=%u,%u,%u,%u status=%s error=0x%04x\n",
                 stage,
                 static_cast<unsigned int>(actual[0]),
                 static_cast<unsigned int>(actual[1]),
                 static_cast<unsigned int>(actual[2]),
                 static_cast<unsigned int>(actual[3]),
                 matches ? "PASS" : "FAIL",
                 error);
    return matches;
}

bool RunRenderTargetSmoke() {
    constexpr GLsizei width = 16;
    constexpr GLsizei height = 16;
    GLuint color_texture = 0;
    GLuint depth_stencil = 0;
    GLuint framebuffer = 0;
    GLuint uploaded_texture = 0;
    GLuint blit_texture = 0;
    GLuint blit_framebuffer = 0;
    bool ok = true;

    glGenTextures(1, &color_texture);
    glBindTexture(GL_TEXTURE_2D, color_texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    glGenRenderbuffers(1, &depth_stencil);
    glBindRenderbuffer(GL_RENDERBUFFER, depth_stencil);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);

    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                           GL_TEXTURE_2D, color_texture, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT,
                              GL_RENDERBUFFER, depth_stencil);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        std::fprintf(stderr, "[TARGET] color + depth/stencil FBO incomplete: 0x%04x\n", status);
        ok = false;
    } else {
        glViewport(0, 0, width, height);
        glDisable(GL_SCISSOR_TEST);
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
        glDepthMask(GL_TRUE);
        glStencilMask(0xFF);
        glClearColor(0.25f, 0.50f, 0.75f, 1.0f);
        glClearDepthf(0.5f);
        glClearStencil(0x5A);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
        glFinish();
        ok = ReadRgbaPixel("FBO clear/readback", {64, 128, 191, 255}) && ok;
    }

    std::array<GLubyte, width * height * 4> pixels{};
    for (std::size_t i = 0; i < pixels.size(); i += 4) {
        pixels[i + 0] = 32;
        pixels[i + 1] = 96;
        pixels[i + 2] = 160;
        pixels[i + 3] = 255;
    }

    glGenTextures(1, &uploaded_texture);
    glBindTexture(GL_TEXTURE_2D, uploaded_texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, pixels.data());
    glGenerateMipmap(GL_TEXTURE_2D);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                           GL_TEXTURE_2D, uploaded_texture, 0);
    status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        std::fprintf(stderr, "[TARGET] uploaded texture FBO incomplete: 0x%04x\n", status);
        ok = false;
    } else {
        glFinish();
        ok = ReadRgbaPixel("texture upload/readback", {32, 96, 160, 255}) && ok;
    }

    glGenTextures(1, &blit_texture);
    glBindTexture(GL_TEXTURE_2D, blit_texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glGenFramebuffers(1, &blit_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, blit_framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                           GL_TEXTURE_2D, blit_texture, 0);
    status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        std::fprintf(stderr, "[TARGET] blit destination FBO incomplete: 0x%04x\n", status);
        ok = false;
    } else {
        glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffer);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, blit_framebuffer);
        glBlitFramebuffer(0, 0, width, height, 0, 0, width, height,
                          GL_COLOR_BUFFER_BIT, GL_NEAREST);
        glBindFramebuffer(GL_FRAMEBUFFER, blit_framebuffer);
        glFinish();
        ok = ReadRgbaPixel("FBO blit/readback", {32, 96, 160, 255}) && ok;
    }

    const GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        std::fprintf(stderr, "[TARGET] GL error after render-target smoke: 0x%04x\n", error);
        ok = false;
    }

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    if (blit_framebuffer) glDeleteFramebuffers(1, &blit_framebuffer);
    if (framebuffer) glDeleteFramebuffers(1, &framebuffer);
    if (depth_stencil) glDeleteRenderbuffers(1, &depth_stencil);
    if (color_texture) glDeleteTextures(1, &color_texture);
    if (uploaded_texture) glDeleteTextures(1, &uploaded_texture);
    if (blit_texture) glDeleteTextures(1, &blit_texture);

    std::fprintf(stderr,
                 "[TARGET] result: %s (RGBA8 + DEPTH24_STENCIL8, upload/mipmap, blit, readback)\n",
                 ok ? "PASS" : "FAIL");
    return ok;
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

    const bool render_targets = built && RunRenderTargetSmoke();
    glFinish();
    const GLenum gl_error = glGetError();
    shaders.Destroy();
    eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    eglDestroyContext(display, context);
    eglDestroySurface(display, surface);
    eglTerminate(display);

    if (!built || !all_programs || !render_targets || gl_error != GL_NO_ERROR) {
        std::fprintf(stderr, "[FAIL] shader-build=%s programs=%s render-targets=%s GL-error=0x%04x\n",
                     built ? "true" : "false", all_programs ? "true" : "false",
                     render_targets ? "true" : "false", gl_error);
        return 4;
    }
    std::fprintf(stderr, "[RESULT] PASS: NativeEE production shaders and GLES render-target/texture/readback smoke passed\n");
    return 0;
}
