#define _POSIX_C_SOURCE 200809L
#include <dlfcn.h>
#include <errno.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
typedef void *EGLDisplay; typedef void *EGLConfig; typedef void *EGLSurface; typedef void *EGLContext; typedef void *EGLNativeDisplayType;
typedef int EGLint; typedef unsigned int EGLBoolean; typedef unsigned int EGLenum; typedef unsigned int GLenum; typedef unsigned char GLubyte; typedef int GLint;
typedef EGLDisplay (*PFN_eglGetDisplay)(EGLNativeDisplayType);
typedef EGLBoolean (*PFN_eglInitialize)(EGLDisplay,EGLint*,EGLint*);
typedef EGLBoolean (*PFN_eglBindAPI)(EGLenum);
typedef EGLBoolean (*PFN_eglChooseConfig)(EGLDisplay,const EGLint*,EGLConfig*,EGLint,EGLint*);
typedef EGLSurface (*PFN_eglCreatePbufferSurface)(EGLDisplay,EGLConfig,const EGLint*);
typedef EGLContext (*PFN_eglCreateContext)(EGLDisplay,EGLConfig,EGLContext,const EGLint*);
typedef EGLBoolean (*PFN_eglMakeCurrent)(EGLDisplay,EGLSurface,EGLSurface,EGLContext);
typedef EGLBoolean (*PFN_eglDestroySurface)(EGLDisplay,EGLSurface);
typedef EGLBoolean (*PFN_eglDestroyContext)(EGLDisplay,EGLContext);
typedef EGLBoolean (*PFN_eglTerminate)(EGLDisplay);
typedef EGLint (*PFN_eglGetError)(void);
typedef const char *(*PFN_eglQueryString)(EGLDisplay,EGLint);
typedef void *(*PFN_eglGetProcAddress)(const char*);
typedef const GLubyte *(*PFN_glGetString)(GLenum);
typedef void (*PFN_glGetIntegerv)(GLenum,GLint*);
#define EGL_NONE 0x3038
#define EGL_DEFAULT_DISPLAY ((EGLNativeDisplayType)0)
#define EGL_NO_DISPLAY ((EGLDisplay)0)
#define EGL_NO_CONTEXT ((EGLContext)0)
#define EGL_NO_SURFACE ((EGLSurface)0)
#define EGL_SURFACE_TYPE 0x3033
#define EGL_PBUFFER_BIT 0x0001
#define EGL_RENDERABLE_TYPE 0x3040
#define EGL_OPENGL_ES3_BIT_KHR 0x0040
#define EGL_RED_SIZE 0x3024
#define EGL_GREEN_SIZE 0x3023
#define EGL_BLUE_SIZE 0x3022
#define EGL_ALPHA_SIZE 0x3021
#define EGL_WIDTH 0x3057
#define EGL_HEIGHT 0x3056
#define EGL_CONTEXT_CLIENT_VERSION 0x3098
#define EGL_CONTEXT_MINOR_VERSION_KHR 0x30FB
#define EGL_OPENGL_ES_API 0x30A0
#define EGL_VENDOR 0x3053
#define EGL_VERSION 0x3054
#define EGL_EXTENSIONS 0x3055
#define GL_VENDOR 0x1F00
#define GL_RENDERER 0x1F01
#define GL_VERSION 0x1F02
#define GL_SHADING_LANGUAGE_VERSION 0x8B8C
#define GL_MAJOR_VERSION 0x821B
#define GL_MINOR_VERSION 0x821C
#define GL_MAX_TEXTURE_SIZE 0x0D33
#define GL_MAX_VERTEX_ATTRIBS 0x8869
#define GL_MAX_TEXTURE_IMAGE_UNITS 0x8872
static FILE *out;
static void logline(const char *fmt, ...) {
    va_list a,b; va_start(a,fmt); va_copy(b,a);
    vfprintf(stdout,fmt,a); fflush(stdout);
    if(out){vfprintf(out,fmt,b);fflush(out);} va_end(b); va_end(a);
}
static int load(void *h,const char *name,void *dst,size_t n) {
    void *p=dlsym(h,name); if(!p||n!=sizeof(p)) return 0; memcpy(dst,&p,n); return 1;
}
static int ext(const char *list,const char *name) {
    size_t n=strlen(name); const char *p=list; if(!p) return 0;
    while((p=strstr(p,name))) { if((p==list||p[-1]==' ')&&(p[n]==' '||p[n]=='\0')) return 1; p+=n; }
    return 0;
}
#define LOAD(sym) do { if(!load(egl,#sym,&sym,sizeof(sym))) { logline("[FAIL] missing EGL symbol %s\n",#sym); goto done; } } while(0)
int main(void) {
    const char *report=getenv("TW_H700_REPORT");
    if(report&&*report) { out=fopen(report,"w"); if(!out) fprintf(stderr,"cannot write %s: %s\n",report,strerror(errno)); }
    logline("Twinsanity Rintromped - H700 EGL/GLES probe\n");
#if defined(__aarch64__)
    logline("[build] ABI=AArch64\n");
#elif defined(__x86_64__)
    logline("[build] ABI=x86_64 (host smoke test only)\n");
#else
    logline("[build] ABI=other\n");
#endif
    const char *vars[]={"SDL_VIDEODRIVER","SDL_AUDIODRIVER","EGL_PLATFORM","GBM_BACKEND","LD_LIBRARY_PATH","LD_PRELOAD","DISPLAY","WAYLAND_DISPLAY","XDG_RUNTIME_DIR",NULL};
    for(int i=0;vars[i];i++) logline("[env] %s=%s\n",vars[i],getenv(vars[i])?getenv(vars[i]):"(unset)");
    const char *names[]={"libEGL.so.1","libEGL.so","libmali.so.1","libmali.so",NULL};
    void *egl=NULL; for(int i=0;names[i]&&!egl;i++){egl=dlopen(names[i],RTLD_NOW|RTLD_LOCAL);if(egl)logline("[load] %s\n",names[i]);}
    const char *gnames[]={"libGLESv2.so.2","libGLESv2.so","libGLESv3.so","libmali.so.1","libmali.so",NULL};
    void *gles=NULL; for(int i=0;gnames[i]&&!gles;i++){gles=dlopen(gnames[i],RTLD_NOW|RTLD_LOCAL);if(gles)logline("[load] %s\n",gnames[i]);}
    if(!egl||!gles){logline("[FAIL] EGL/GLES shared libraries unavailable\n");if(egl)dlclose(egl);if(gles)dlclose(gles);if(out)fclose(out);return 2;}
    PFN_eglGetDisplay eglGetDisplay=NULL; PFN_eglInitialize eglInitialize=NULL; PFN_eglBindAPI eglBindAPI=NULL;
    PFN_eglChooseConfig eglChooseConfig=NULL; PFN_eglCreatePbufferSurface eglCreatePbufferSurface=NULL; PFN_eglCreateContext eglCreateContext=NULL;
    PFN_eglMakeCurrent eglMakeCurrent=NULL; PFN_eglDestroySurface eglDestroySurface=NULL; PFN_eglDestroyContext eglDestroyContext=NULL;
    PFN_eglTerminate eglTerminate=NULL; PFN_eglGetError eglGetError=NULL; PFN_eglQueryString eglQueryString=NULL; PFN_eglGetProcAddress eglGetProcAddress=NULL;
    EGLDisplay d=EGL_NO_DISPLAY; EGLSurface s=EGL_NO_SURFACE; EGLContext c=EGL_NO_CONTEXT; int rc=3;
    LOAD(eglGetDisplay); LOAD(eglInitialize); LOAD(eglBindAPI); LOAD(eglChooseConfig); LOAD(eglCreatePbufferSurface); LOAD(eglCreateContext);
    LOAD(eglMakeCurrent); LOAD(eglDestroySurface); LOAD(eglDestroyContext); LOAD(eglTerminate); LOAD(eglGetError); LOAD(eglQueryString); LOAD(eglGetProcAddress);
    EGLint ma=0,mi=0; d=eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if(d==EGL_NO_DISPLAY||!eglInitialize(d,&ma,&mi)){logline("[FAIL] EGL display/init failed: 0x%04x\n",eglGetError());goto done;}
    logline("[EGL] version=%d.%d vendor=%s\n",ma,mi,eglQueryString(d,EGL_VENDOR)?eglQueryString(d,EGL_VENDOR):"?");
    logline("[EGL] runtime=%s\n",eglQueryString(d,EGL_VERSION)?eglQueryString(d,EGL_VERSION):"?");
    const char *ee=eglQueryString(d,EGL_EXTENSIONS); logline("[EGL] extensions=%s\n",ee?ee:"(unavailable)");
    if(!eglBindAPI(EGL_OPENGL_ES_API)){logline("[FAIL] eglBindAPI ES failed: 0x%04x\n",eglGetError());goto done;}
    const EGLint ca[]={EGL_SURFACE_TYPE,EGL_PBUFFER_BIT,EGL_RENDERABLE_TYPE,EGL_OPENGL_ES3_BIT_KHR,EGL_RED_SIZE,8,EGL_GREEN_SIZE,8,EGL_BLUE_SIZE,8,EGL_ALPHA_SIZE,8,EGL_NONE};
    EGLConfig cfg=NULL; EGLint count=0;
    if(!eglChooseConfig(d,ca,&cfg,1,&count)||count<1){logline("[FAIL] no ES3 pbuffer config: 0x%04x\n",eglGetError());goto done;}
    const EGLint pa[]={EGL_WIDTH,16,EGL_HEIGHT,16,EGL_NONE}; s=eglCreatePbufferSurface(d,cfg,pa);
    if(s==EGL_NO_SURFACE){logline("[FAIL] pbuffer creation failed: 0x%04x\n",eglGetError());goto done;}
    if(ext(ee,"EGL_KHR_create_context")) {
        const EGLint a32[]={EGL_CONTEXT_CLIENT_VERSION,3,EGL_CONTEXT_MINOR_VERSION_KHR,2,EGL_NONE};
        logline("[EGL] requesting ES 3.2\n"); c=eglCreateContext(d,cfg,EGL_NO_CONTEXT,a32);
        if(c==EGL_NO_CONTEXT)logline("[WARN] ES 3.2 request failed: 0x%04x; trying ES 3.x\n",eglGetError());
    } else logline("[WARN] EGL_KHR_create_context absent; requesting ES 3.x\n");
    if(c==EGL_NO_CONTEXT){const EGLint a3[]={EGL_CONTEXT_CLIENT_VERSION,3,EGL_NONE};c=eglCreateContext(d,cfg,EGL_NO_CONTEXT,a3);}
    if(c==EGL_NO_CONTEXT){logline("[FAIL] ES3 context creation failed: 0x%04x\n",eglGetError());goto done;}
    if(!eglMakeCurrent(d,s,s,c)){logline("[FAIL] eglMakeCurrent failed: 0x%04x\n",eglGetError());goto done;}
    PFN_glGetString gs=NULL; PFN_glGetIntegerv gi=NULL; void *p=eglGetProcAddress("glGetString");
    if (!p) p = dlsym(gles, "glGetString");
    if (p && sizeof(p) == sizeof(gs)) memcpy(&gs, &p, sizeof(p));
    p = eglGetProcAddress("glGetIntegerv");
    if (!p) p = dlsym(gles, "glGetIntegerv");
    if (p && sizeof(p) == sizeof(gi)) memcpy(&gi, &p, sizeof(p));
    if(!gs||!gi){logline("[FAIL] GLES entry point resolution failed\n");goto done;}
    GLint major=0,minor=0,lim=0; gi(GL_MAJOR_VERSION,&major); gi(GL_MINOR_VERSION,&minor);
    logline("[GL] vendor=%s\n",gs(GL_VENDOR)?(const char*)gs(GL_VENDOR):"?");
    logline("[GL] renderer=%s\n",gs(GL_RENDERER)?(const char*)gs(GL_RENDERER):"?");
    logline("[GL] version=%s (%d.%d)\n",gs(GL_VERSION)?(const char*)gs(GL_VERSION):"?",major,minor);
    logline("[GL] GLSL=%s\n",gs(GL_SHADING_LANGUAGE_VERSION)?(const char*)gs(GL_SHADING_LANGUAGE_VERSION):"?");
    gi(GL_MAX_TEXTURE_SIZE,&lim); logline("[LIMIT] GL_MAX_TEXTURE_SIZE=%d\n",lim);
    gi(GL_MAX_VERTEX_ATTRIBS,&lim); logline("[LIMIT] GL_MAX_VERTEX_ATTRIBS=%d\n",lim);
    gi(GL_MAX_TEXTURE_IMAGE_UNITS,&lim); logline("[LIMIT] GL_MAX_TEXTURE_IMAGE_UNITS=%d\n",lim);
    logline("[GL] extensions=%s\n",gs(0x1F03)?(const char*)gs(0x1F03):"(unavailable)");
    if(major>3||(major==3&&minor>=2)){logline("[RESULT] PASS: GLES 3.2+ context works; renderer API audit still required.\n");rc=0;}
    else {logline("[RESULT] WARN: GLES %d.%d found; preferred target is 3.2.\n",major,minor);rc=5;}
done:
    if(d!=EGL_NO_DISPLAY){eglMakeCurrent(d,EGL_NO_SURFACE,EGL_NO_SURFACE,EGL_NO_CONTEXT);if(c!=EGL_NO_CONTEXT)eglDestroyContext(d,c);if(s!=EGL_NO_SURFACE)eglDestroySurface(d,s);eglTerminate(d);}
    dlclose(gles); dlclose(egl); if(out)fclose(out); return rc;
}
