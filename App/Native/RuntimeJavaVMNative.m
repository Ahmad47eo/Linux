#include "RuntimeJavaVMNative.h"
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>

#ifndef JNI_VERSION_1_8
#define JNI_VERSION_1_8 0x00010008
#endif

typedef int32_t jint;
typedef uint8_t jboolean;
typedef struct JavaVM_ JavaVM;
typedef struct { char *optionString; void *extraInfo; } JavaVMOption;
typedef struct { jint version; jint nOptions; JavaVMOption *options; jboolean ignoreUnrecognized; } JavaVMInitArgs;
typedef jint (*CreateVM)(JavaVM **, void **, void *);
typedef jint (*DestroyVM)(JavaVM *);

static JavaVM *g_vm;
static void *g_handle;
static char g_error[512];

static void set_error(const char *message) {
    strncpy(g_error, message ? message : "Unknown Java VM error.", sizeof(g_error) - 1);
    g_error[sizeof(g_error) - 1] = '\\0';
}

int runtime_java_vm_start(const char *runtimeDirectory, const char *classPath, const char *options) {
    if (g_vm) { set_error("A Java VM is already running."); return 1; }
    char library[2048];
    snprintf(library, sizeof(library), "%s/lib/server/libjvm.dylib", runtimeDirectory);
    g_handle = dlopen(library, RTLD_NOW | RTLD_LOCAL);
    if (!g_handle) { set_error(dlerror()); return 2; }
    CreateVM create = (CreateVM)dlsym(g_handle, "JNI_CreateJavaVM");
    if (!create) { set_error("JNI_CreateJavaVM was not exported by this runtime."); dlclose(g_handle); g_handle=NULL; return 3; }

    char cp[2048];
    snprintf(cp, sizeof(cp), "-Djava.class.path=%s", classPath ? classPath : "");
    JavaVMOption vmOptions[2];
    vmOptions[0].optionString = cp; vmOptions[0].extraInfo = NULL;
    int count = 1;
    if (options && options[0]) { vmOptions[1].optionString = (char *)options; vmOptions[1].extraInfo = NULL; count = 2; }
    JavaVMInitArgs args = { JNI_VERSION_1_8, count, vmOptions, 1 };
    void *env = NULL;
    jint result = create(&g_vm, &env, &args);
    if (result != 0 || !g_vm) {
        char message[128]; snprintf(message, sizeof(message), "JNI_CreateJavaVM failed with code %d.", result);
        set_error(message); g_vm=NULL; dlclose(g_handle); g_handle=NULL; return 4;
    }
    g_error[0]='\\0';
    return 0;
}

int runtime_java_vm_running(void) { return g_vm != NULL; }

int runtime_java_vm_stop(void) {
    if (!g_vm) return 0;
    DestroyVM destroy = g_handle ? (DestroyVM)dlsym(g_handle, "JNI_DestroyJavaVM") : NULL;
    if (destroy) destroy(g_vm);
    g_vm=NULL;
    if (g_handle) { dlclose(g_handle); g_handle=NULL; }
    return 0;
}

const char *runtime_java_vm_last_error(void) { return g_error; }
