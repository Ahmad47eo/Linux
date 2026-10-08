#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RuntimeJavaVMResult) {
    RuntimeJavaVMResultSuccess = 0,
    RuntimeJavaVMResultAlreadyRunning = 1,
    RuntimeJavaVMResultLibraryNotFound = 2,
    RuntimeJavaVMResultCreateFailed = 3
};

@interface RuntimeJavaVMBridge : NSObject

@property (nonatomic, readonly) BOOL running;

- (RuntimeJavaVMResult)startWithRuntimeDirectory:(NSString *)runtimeDirectory
                                     classPath:(NSString *)classPath
                                       options:(NSArray<NSString *> *)options
                                         error:(NSError * _Nullable * _Nullable)error;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
