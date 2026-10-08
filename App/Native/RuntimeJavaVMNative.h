#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int runtime_java_vm_start(const char *runtimeDirectory, const char *classPath, const char *options);
int runtime_java_vm_running(void);
int runtime_java_vm_stop(void);
const char *runtime_java_vm_last_error(void);

#ifdef __cplusplus
}
#endif
