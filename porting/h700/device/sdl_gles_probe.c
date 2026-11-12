#define _POSIX_C_SOURCE 200809L
#include <dlfcn.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

typedef struct SDL_Window SDL_Window;
typedef void *SDL_GLContext;
typedef uint32_t SDL_Uint32;
typedef int (*PFN_SDL_Init)(SDL_Uint32);
typedef void (*PFN_SDL_Quit)(void);
typedef int (*PFN_SDL_GL_SetAttribute)(int, int);
typedef SDL_Window *(*PFN_SDL_CreateWindow)(const char *, int, int, int, int, SDL_Uint32);
typedef void (*PFN_SDL_DestroyWindow)(SDL_Window *);
typedef SDL_GLContext (*PFN_SDL_GL_CreateContext)(SDL_Window *);
typedef int (*PFN_SDL_GL_MakeCurrent)(SDL_Window *, SDL_GLContext);
typedef void (*PFN_SDL_GL_DeleteContext)(SDL_GLContext);
typedef void (*PFN_SDL_GL_SwapWindow)(SDL_Window *);
typedef void *(*PFN_SDL_GL_GetProcAddress)(const char *);
typedef int (*PFN_SDL_GL_GetAttribute)(int, int *);
typedef const char *(*PFN_SDL_GetError)(void);
typedef const char *(*PFN_SDL_GetCurrentVideoDriver)(void);
typedef void (*PFN_SDL_PumpEvents)(void);
typedef void (*PFN_SDL_Delay)(SDL_Uint32);
typedef const unsigned char *(*PFN_glGetString)(unsigned int);
typedef void (*PFN_glClearColor)(float, float, float, float);
typedef void (*PFN_glClear)(unsigned int);
typedef unsigned int (*PFN_glGetError)(void);
typedef void (*PFN_glViewport)(int, int, int, int);

#define SDL_INIT_VIDEO 0x00000020u
#define SDL_WINDOW_OPENGL 0x00000002u
#define SDL_WINDOW_SHOWN 0x00000004u
#define SDL_WINDOWPOS_CENTERED 0x2FFF0000
#define SDL_GL_RED_SIZE 0
#define SDL_GL_GREEN_SIZE 1
#define SDL_GL_BLUE_SIZE 2
#define SDL_GL_ALPHA_SIZE 3
#define SDL_GL_DOUBLEBUFFER 5
#define SDL_GL_DEPTH_SIZE 6
#define SDL_GL_STENCIL_SIZE 7
#define SDL_GL_CONTEXT_MAJOR_VERSION 17
#define SDL_GL_CONTEXT_MINOR_VERSION 18
#define SDL_GL_CONTEXT_PROFILE_MASK 21
#define SDL_GL_CONTEXT_PROFILE_ES 0x0004
#define GL_VENDOR 0x1F00u
#define GL_RENDERER 0x1F01u
#define GL_VERSION 0x1F02u
#define GL_SHADING_LANGUAGE_VERSION 0x8B8Cu
#define GL_COLOR_BUFFER_BIT 0x00004000u

static FILE *out;
static void logline(const char *fmt, ...) {
    va_list a, b;
    va_start(a, fmt);
    va_copy(b, a);
    vfprintf(stdout, fmt, a);
    fflush(stdout);
    if (out) {
        vfprintf(out, fmt, b);
        fflush(out);
    }
    va_end(b);
    va_end(a);
}

static int load_symbol(void *handle, const char *name, void *destination, size_t size) {
    void *symbol = dlsym(handle, name);
    if (!symbol || size != sizeof(symbol)) return 0;
    memcpy(destination, &symbol, size);
    return 1;
}

static int load_sdl(void *handle,
                    PFN_SDL_Init *init, PFN_SDL_Quit *quit,
                    PFN_SDL_GL_SetAttribute *set_attribute,
                    PFN_SDL_CreateWindow *create_window,
                    PFN_SDL_DestroyWindow *destroy_window,
                    PFN_SDL_GL_CreateContext *create_context,
                    PFN_SDL_GL_MakeCurrent *make_current,
                    PFN_SDL_GL_DeleteContext *delete_context,
                    PFN_SDL_GL_SwapWindow *swap_window,
                    PFN_SDL_GL_GetProcAddress *get_proc_address,
                    PFN_SDL_GL_GetAttribute *get_attribute,
                    PFN_SDL_GetError *get_error,
                    PFN_SDL_GetCurrentVideoDriver *get_video_driver,
                    PFN_SDL_PumpEvents *pump_events,
                    PFN_SDL_Delay *delay) {
#define LOAD_SDL(name, variable) do { \
    if (!load_symbol(handle, name, variable, sizeof(*variable))) { \
        logline("[FAIL] missing SDL symbol %s\n", name); return 0; \
    } \
} while (0)
    LOAD_SDL("SDL_Init", init);
    LOAD_SDL("SDL_Quit", quit);
    LOAD_SDL("SDL_GL_SetAttribute", set_attribute);
    LOAD_SDL("SDL_CreateWindow", create_window);
    LOAD_SDL("SDL_DestroyWindow", destroy_window);
    LOAD_SDL("SDL_GL_CreateContext", create_context);
    LOAD_SDL("SDL_GL_MakeCurrent", make_current);
    LOAD_SDL("SDL_GL_DeleteContext", delete_context);
    LOAD_SDL("SDL_GL_SwapWindow", swap_window);
    LOAD_SDL("SDL_GL_GetProcAddress", get_proc_address);
    LOAD_SDL("SDL_GL_GetAttribute", get_attribute);
    LOAD_SDL("SDL_GetError", get_error);
    LOAD_SDL("SDL_GetCurrentVideoDriver", get_video_driver);
    LOAD_SDL("SDL_PumpEvents", pump_events);
    LOAD_SDL("SDL_Delay", delay);
#undef LOAD_SDL
    return 1;
}

static void *open_sdl(void) {
    static const char *const names[] = {
        "libSDL2-2.0.so.0", "libSDL2-2.0.so", "libSDL2.so",
        "/opt/muos/lib/libSDL2-2.0.so.0",
        "/usr/lib/aarch64-linux-gnu/libSDL2-2.0.so.0",
        "/lib/aarch64-linux-gnu/libSDL2-2.0.so.0", NULL
    };
    for (size_t i = 0; names[i]; ++i) {
        void *handle = dlopen(names[i], RTLD_NOW | RTLD_LOCAL);
        if (handle) {
            logline("[load] %s\n", names[i]);
            return handle;
        }
    }
    return NULL;
}

static int parse_es_version(const char *version, int *major, int *minor) {
    if (!version) return 0;
    const char *p = version;
    while (*p && (*p < '0' || *p > '9')) ++p;
    return sscanf(p, "%d.%d", major, minor) == 2;
}

static int get_gl_proc(PFN_SDL_GL_GetProcAddress get_proc,
                       const char *name, void *destination, size_t size) {
    void *symbol = get_proc(name);
    if (!symbol || size != sizeof(symbol)) return 0;
    memcpy(destination, &symbol, size);
    return 1;
}

int main(void) {
    const char *report = getenv("TW_H700_SDL_REPORT");
    if (report && *report) {
        out = fopen(report, "w");
        if (!out) fprintf(stderr, "cannot write %s: %s\n", report, strerror(errno));
    }
    logline("Twinsanity Rintromped - H700 SDL/GLES window probe\n");
#if defined(__aarch64__)
    logline("[build] ABI=AArch64\n");
#elif defined(__x86_64__)
    logline("[build] ABI=x86_64 (host smoke test only)\n");
#else
    logline("[build] ABI=other\n");
#endif
    const char *vars[] = {"SDL_VIDEODRIVER", "EGL_PLATFORM", "GBM_BACKEND", "DISPLAY",
                          "WAYLAND_DISPLAY", "XDG_RUNTIME_DIR", "LD_LIBRARY_PATH", NULL};
    for (size_t i = 0; vars[i]; ++i)
        logline("[env] %s=%s\n", vars[i], getenv(vars[i]) ? getenv(vars[i]) : "(unset)");

    void *sdl = open_sdl();
    if (!sdl) {
        const char *error = dlerror();
        logline("[FAIL] SDL2 shared library unavailable: %s\n", error ? error : "not found");
        if (out) fclose(out);
        return 2;
    }

    PFN_SDL_Init init = NULL;
    PFN_SDL_Quit quit = NULL;
    PFN_SDL_GL_SetAttribute set_attribute = NULL;
    PFN_SDL_CreateWindow create_window = NULL;
    PFN_SDL_DestroyWindow destroy_window = NULL;
    PFN_SDL_GL_CreateContext create_context = NULL;
    PFN_SDL_GL_MakeCurrent make_current = NULL;
    PFN_SDL_GL_DeleteContext delete_context = NULL;
    PFN_SDL_GL_SwapWindow swap_window = NULL;
    PFN_SDL_GL_GetProcAddress get_proc_address = NULL;
    PFN_SDL_GL_GetAttribute get_attribute = NULL;
    PFN_SDL_GetError get_error = NULL;
    PFN_SDL_GetCurrentVideoDriver get_video_driver = NULL;
    PFN_SDL_PumpEvents pump_events = NULL;
    PFN_SDL_Delay delay = NULL;
    if (!load_sdl(sdl, &init, &quit, &set_attribute, &create_window, &destroy_window,
                  &create_context, &make_current, &delete_context, &swap_window,
                  &get_proc_address, &get_attribute, &get_error, &get_video_driver,
                  &pump_events, &delay)) {
        dlclose(sdl);
        if (out) fclose(out);
        return 3;
    }

    logline("[SDL] Init video subsystem\n");
    if (init(SDL_INIT_VIDEO) != 0) {
        logline("[FAIL] SDL_Init: %s\n", get_error());
        dlclose(sdl);
        if (out) fclose(out);
        return 3;
    }
    const char *driver = get_video_driver();
    logline("[SDL] video_driver=%s\n", driver ? driver : "(unknown)");

    struct { int attribute; int value; const char *name; } attrs[] = {
        {SDL_GL_CONTEXT_MAJOR_VERSION, 3, "context_major=3"},
        {SDL_GL_CONTEXT_MINOR_VERSION, 2, "context_minor=2"},
        {SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES, "context_profile=ES"},
        {SDL_GL_RED_SIZE, 8, "red=8"}, {SDL_GL_GREEN_SIZE, 8, "green=8"},
        {SDL_GL_BLUE_SIZE, 8, "blue=8"}, {SDL_GL_ALPHA_SIZE, 8, "alpha=8"},
        {SDL_GL_DEPTH_SIZE, 24, "depth=24"}, {SDL_GL_STENCIL_SIZE, 8, "stencil=8"},
        {SDL_GL_DOUBLEBUFFER, 1, "doublebuffer=1"}
    };
    for (size_t i = 0; i < sizeof(attrs) / sizeof(attrs[0]); ++i) {
        if (set_attribute(attrs[i].attribute, attrs[i].value) != 0)
            logline("[WARN] SDL_GL_SetAttribute %s: %s\n", attrs[i].name, get_error());
    }

    SDL_Window *window = create_window("Twinsanity H700 SDL/GLES preflight",
                                       SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                       640, 480, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
    if (!window) {
        logline("[FAIL] SDL_CreateWindow: %s\n", get_error());
        quit(); dlclose(sdl); if (out) fclose(out); return 3;
    }
    SDL_GLContext context = create_context(window);
    if (!context) {
        logline("[FAIL] SDL_GL_CreateContext (ES 3.2): %s\n", get_error());
        destroy_window(window); quit(); dlclose(sdl); if (out) fclose(out); return 3;
    }
    if (make_current(window, context) != 0) {
        logline("[FAIL] SDL_GL_MakeCurrent: %s\n", get_error());
        delete_context(context); destroy_window(window); quit(); dlclose(sdl); if (out) fclose(out); return 3;
    }

    int requested_major = 0, requested_minor = 0, profile = 0;
    (void)get_attribute(SDL_GL_CONTEXT_MAJOR_VERSION, &requested_major);
    (void)get_attribute(SDL_GL_CONTEXT_MINOR_VERSION, &requested_minor);
    (void)get_attribute(SDL_GL_CONTEXT_PROFILE_MASK, &profile);
    logline("[SDL] context_attributes major=%d minor=%d profile=0x%x\n",
            requested_major, requested_minor, profile);

    PFN_glGetString get_string = NULL;
    PFN_glClearColor clear_color = NULL;
    PFN_glClear clear = NULL;
    PFN_glGetError get_gl_error = NULL;
    PFN_glViewport viewport = NULL;
    if (!get_gl_proc(get_proc_address, "glGetString", &get_string, sizeof(get_string)) ||
        !get_gl_proc(get_proc_address, "glClearColor", &clear_color, sizeof(clear_color)) ||
        !get_gl_proc(get_proc_address, "glClear", &clear, sizeof(clear)) ||
        !get_gl_proc(get_proc_address, "glGetError", &get_gl_error, sizeof(get_gl_error)) ||
        !get_gl_proc(get_proc_address, "glViewport", &viewport, sizeof(viewport))) {
        logline("[FAIL] cannot resolve required GLES entry points\n");
        delete_context(context); destroy_window(window); quit(); dlclose(sdl); if (out) fclose(out); return 6;
    }

    const char *version = (const char *)get_string(GL_VERSION);
    const char *vendor = (const char *)get_string(GL_VENDOR);
    const char *renderer = (const char *)get_string(GL_RENDERER);
    const char *glsl = (const char *)get_string(GL_SHADING_LANGUAGE_VERSION);
    int major = 0, minor = 0;
    const int parsed = parse_es_version(version, &major, &minor);
    logline("[GL] vendor=%s\n", vendor ? vendor : "?");
    logline("[GL] renderer=%s\n", renderer ? renderer : "?");
    logline("[GL] version=%s\n", version ? version : "?");
    logline("[GL] GLSL=%s\n", glsl ? glsl : "?");
    viewport(0, 0, 640, 480);

    static const float colors[][4] = {
        {0.10f, 0.20f, 0.45f, 1.0f}, {0.10f, 0.50f, 0.20f, 1.0f},
        {0.65f, 0.15f, 0.12f, 1.0f}, {0.05f, 0.55f, 0.60f, 1.0f},
        {0.60f, 0.35f, 0.08f, 1.0f}, {0.30f, 0.20f, 0.55f, 1.0f}
    };
    logline("[VISUAL] swapping six solid-color frames; the panel should visibly change color.\n");
    int render_error = 0;
    for (size_t i = 0; i < sizeof(colors) / sizeof(colors[0]); ++i) {
        clear_color(colors[i][0], colors[i][1], colors[i][2], colors[i][3]);
        clear(GL_COLOR_BUFFER_BIT);
        pump_events();
        swap_window(window);
        const unsigned int err = get_gl_error();
        if (err != 0) {
            logline("[FAIL] GLES error after swap %zu: 0x%04x\n", i, err);
            render_error = 1;
            break;
        }
        delay(180);
    }
    if (!render_error && parsed && (major > 3 || (major == 3 && minor >= 2)))
        logline("[RESULT] PASS: SDL window, GLES 3.2+ context and buffer swaps work. Game renderer is not tested.\n");
    else if (!render_error)
        logline("[RESULT] WARN: window swaps ran, but GLES 3.2+ was not confirmed.\n");

    delete_context(context);
    destroy_window(window);
    quit();
    dlclose(sdl);
    if (out) fclose(out);
    if (render_error) return 6;
    return parsed && (major > 3 || (major == 3 && minor >= 2)) ? 0 : 5;
}
