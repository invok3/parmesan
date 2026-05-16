#pragma once
#include <string>
#include <windows.h>
#include <stdint.h>

#if defined(_WIN32)
    #define FFI_EXPORT extern "C" __declspec(dllexport)
#else
    #define FFI_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif

// Predefined function signature for the database update method
typedef int (*DbUpdateFunc)(int32_t record_id, int32_t payload);

class ModuleBridge {
private:
    HMODULE db_handler_handle = nullptr;
    
    // Cached function pointers to avoid calling GetProcAddress repeatedly
    DbUpdateFunc db_update_ptr = nullptr;

    ModuleBridge() = default;

public:
    static ModuleBridge& instance() {
        static ModuleBridge inst;
        return inst;
    }

    // Clean resource management
    ~ModuleBridge() { unload_all(); }

    // 1st) Explicit initialization step called at app startup
    bool load_all_modules();
    void unload_all();

    // 2nd) Predefined getter for execution
    DbUpdateFunc get_db_update() const { return db_update_ptr; }
};

// Purely type-safe, explicit FFI entry points for Flutter
FFI_EXPORT bool bridge_initialize();
FFI_EXPORT int bridge_db_update(int32_t record_id, int32_t payload);