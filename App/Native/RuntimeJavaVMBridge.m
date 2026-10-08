#import "RuntimeJavaVMBridge.h"
#import <dlfcn.h>
#import <pthread.h>

typedef int32_t jint;
typedef int32_t jsize;
typedef uint8_t jboolean;

typedef struct JavaVM_ JavaVM;
typedef const struct JNIEnv_ JNIEnv;

typedef struct {
    char *optionString;
    void *extraInfo;
} RuntimeJavaVMOption;

typedef struct {
    jint version;
    jint nOptions;
    RuntimeJavaVMOption *options;
    jboolean ignoreUnrecognized;
} RuntimeJavaVMInitArgs;

typedef jint (*RuntimeJNI_CreateJavaVM)(JavaVM **, void **, void *);

static NSString * const RuntimeJavaVMErrorDomain = @"RuntimeApp.JavaVM";

@interface RuntimeJavaVMBridge () {
    JavaVM *_vm;
    void *_libraryHandle;
}
@end

@implementation RuntimeJavaVMBridge

- (BOOL)running {
    return _vm != NULL;
}

- (RuntimeJavaVMResult)startWithRuntimeDirectory:(NSString *)runtimeDirectory
                                     classPath:(NSString *)classPath
                                       options:(NSArray<NSString *> *)options
                                         error:(NSError **)error {
    if (_vm != NULL) {
        return RuntimeJavaVMResultAlreadyRunning;
    }

    NSString *libraryPath = [runtimeDirectory stringByAppendingPathComponent:@"lib/server/libjvm.dylib"];
    _libraryHandle = dlopen(libraryPath.fileSystemRepresentation, RTLD_NOW | RTLD_LOCAL);
    if (_libraryHandle == NULL) {
        if (error) {
            *error = [NSError errorWithDomain:RuntimeJavaVMErrorDomain
                                         code:RuntimeJavaVMResultLibraryNotFound
                                     userInfo:@{NSLocalizedDescriptionKey:
                                                    @"No compatible libjvm.dylib was found in the imported runtime."}];
        }
        return RuntimeJavaVMResultLibraryNotFound;
    }

    RuntimeJNI_CreateJavaVM createVM =
        (RuntimeJNI_CreateJavaVM)dlsym(_libraryHandle, "JNI_CreateJavaVM");

    if (createVM == NULL) {
        dlclose(_libraryHandle);
        _libraryHandle = NULL;
        if (error) {
            *error = [NSError errorWithDomain:RuntimeJavaVMErrorDomain
                                         code:RuntimeJavaVMResultCreateFailed
                                     userInfo:@{NSLocalizedDescriptionKey:
                                                    @"The imported VM does not export JNI_CreateJavaVM."}];
        }
        return RuntimeJavaVMResultCreateFailed;
    }

    NSMutableArray<NSData *> *optionStorage = [NSMutableArray array];
    NSMutableArray<NSValue *> *pointerStorage = [NSMutableArray array];

    NSString *classpathOption = [NSString stringWithFormat:@"-Djava.class.path=%@", classPath];
    NSArray<NSString *> *allOptions = [options arrayByAddingObject:classpathOption];

    for (NSString *string in allOptions) {
        NSData *data = [[string dataUsingEncoding:NSUTF8StringEncoding]
                        mutableCopy];
        NSMutableData *mutableData = [data mutableCopy];
        uint8_t zero = 0;
        [mutableData appendBytes:&zero length:1];
        [optionStorage addObject:mutableData];
        [pointerStorage addObject:[NSValue valueWithPointer:mutableData.mutableBytes]];
    }

    RuntimeJavaVMOption *vmOptions = calloc(allOptions.count, sizeof(RuntimeJavaVMOption));
    for (NSUInteger i = 0; i < allOptions.count; i++) {
        vmOptions[i].optionString = (char *)pointerStorage[i].pointerValue;
    }

    RuntimeJavaVMInitArgs args;
    args.version = 0x00010008;
    args.nOptions = (jint)allOptions.count;
    args.options = vmOptions;
    args.ignoreUnrecognized = 1;

    void *env = NULL;
    jint result = createVM(&_vm, &env, &args);
    free(vmOptions);

    if (result != 0 || _vm == NULL) {
        _vm = NULL;
        dlclose(_libraryHandle);
        _libraryHandle = NULL;

        if (error) {
            *error = [NSError errorWithDomain:RuntimeJavaVMErrorDomain
                                         code:RuntimeJavaVMResultCreateFailed
                                     userInfo:@{NSLocalizedDescriptionKey:
                                                    [NSString stringWithFormat:@"JNI_CreateJavaVM failed (%d).", result]}];
        }
        return RuntimeJavaVMResultCreateFailed;
    }

    return RuntimeJavaVMResultSuccess;
}

- (void)stop {
    if (_vm == NULL) {
        return;
    }

    typedef jint (*RuntimeDestroyJavaVM)(JavaVM *);
    RuntimeDestroyJavaVM destroyVM = NULL;

    if (_libraryHandle != NULL) {
        destroyVM = (RuntimeDestroyJavaVM)dlsym(_libraryHandle, "JNI_DestroyJavaVM");
    }

    if (destroyVM != NULL) {
        destroyVM(_vm);
    }

    _vm = NULL;

    if (_libraryHandle != NULL) {
        dlclose(_libraryHandle);
        _libraryHandle = NULL;
    }
}

- (void)dealloc {
    [self stop];
}

@end
