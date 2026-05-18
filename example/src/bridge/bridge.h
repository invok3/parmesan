#ifndef BRIDGE_H
#define BRIDGE_H

#if defined(_WIN32)
    #define FFI_EXPORT extern "C" __declspec(dllexport)
#else
    #define FFI_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif

#ifdef _WIN32
#include <windows.h>
typedef HMODULE ModuleHandle;
#else
#include <dlfcn.h>
typedef void* ModuleHandle;
#endif

#include <stdint.h>
#include <iostream>

// Module function pointer typedefs
{{MODULE_TYPEDEFS}}

class ModuleBridge {
public:
    static ModuleBridge& instance();

    bool load_all_modules();
    void unload_all_modules();

{{MODULE_GETTERS}}

private:
    ModuleBridge();
    ~ModuleBridge();
    ModuleBridge(const ModuleBridge&) = delete;
    ModuleBridge& operator=(const ModuleBridge&) = delete;

    ModuleHandle load_module(const std::string& name);
    void* resolve_symbol(ModuleHandle handle, const std::string& symbol);
    void unload_module(ModuleHandle handle);

{{MODULE_HANDLES}}
};

// FFI entry points
FFI_EXPORT int bridge_initialize();

{{FFI_EXPORTS}}

#endif // BRIDGE_H
