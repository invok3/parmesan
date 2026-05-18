#include "bridge.h"
#include <iostream>
#include <string>

#ifdef _WIN32
#define MODULE_EXTENSION ".dll"
#define MODULE_PATH_SEPARATOR "\\"
#else
#define MODULE_EXTENSION ".so"
#define MODULE_PATH_SEPARATOR "/"
#endif

ModuleBridge::ModuleBridge() {}

ModuleBridge::~ModuleBridge() {
    unload_all_modules();
}

ModuleBridge& ModuleBridge::instance() {
    static ModuleBridge instance;
    return instance;
}

ModuleHandle ModuleBridge::load_module(const std::string& name) {
#ifdef _WIN32
    std::string path = name + MODULE_EXTENSION;
    HMODULE handle = LoadLibraryA(path.c_str());
    if (!handle) {
        std::cerr << "LoadLibrary failed for " << path << std::endl;
    }
    return handle;
#else
    std::string path = "./" + name + MODULE_EXTENSION;
    void* handle = dlopen(path.c_str(), RTLD_LAZY);
    if (!handle) {
        std::cerr << "dlopen failed for " << path << ": " << dlerror() << std::endl;
    }
    return handle;
#endif
}

void* ModuleBridge::resolve_symbol(ModuleHandle handle, const std::string& symbol) {
#ifdef _WIN32
    void* addr = (void*)GetProcAddress(handle, symbol.c_str());
    if (!addr) {
        std::cerr << "GetProcAddress failed for " << symbol << std::endl;
    }
    return addr;
#else
    void* addr = dlsym(handle, symbol.c_str());
    if (!addr) {
        std::cerr << "dlsym failed for " << symbol << ": " << dlerror() << std::endl;
    }
    return addr;
#endif
}

void ModuleBridge::unload_module(ModuleHandle handle) {
#ifdef _WIN32
    if (handle) FreeLibrary(handle);
#else
    if (handle) dlclose(handle);
#endif
}

bool ModuleBridge::load_all_modules() {
{{MODULE_LOADS}}

    std::cout << "All modules loaded successfully" << std::endl;
    return true;
}

void ModuleBridge::unload_all_modules() {
{{MODULE_UNLOADS}}
}

{{MODULE_GETTERS_IMPLS}}

// FFI entry points
FFI_EXPORT int bridge_initialize() {
    if (!ModuleBridge::instance().load_all_modules()) {
        return -1;
    }
    return 0;
}

{{FFI_IMPLS}}
