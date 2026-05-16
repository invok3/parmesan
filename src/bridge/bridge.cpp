#include "bridge.h"
#include <iostream>

bool ModuleBridge::load_all_modules() {
    // 1st) Hardcoded loading of the known "dbHandler" module
    // We expect the modules subfolder to live next to our main executable
    if (db_handler_handle == nullptr) {
        db_handler_handle = LoadLibraryA("modules\\dbHandler.dll");
        if (!db_handler_handle) {
            return false; 
        }

        // 2nd) Cache the predefined method pointers immediately upon load
        db_update_ptr = (DbUpdateFunc)GetProcAddress(db_handler_handle, "db_update_record");
        if (!db_update_ptr) {
            // Fail fast if a known method is missing from the module
            FreeLibrary(db_handler_handle);
            db_handler_handle = nullptr;
            return false;
        }
    }
    
    // Add other modules here (e.g., processing_handle, etc.)
    return true;
}

void ModuleBridge::unload_all() {
    if (db_handler_handle) {
        FreeLibrary(db_handler_handle);
        db_handler_handle = nullptr;
        db_update_ptr = nullptr;
    }
}

// ==========================================
// FFI Glue Code (Direct, Type-Safe)
// ==========================================

FFI_EXPORT bool bridge_initialize() {
    return ModuleBridge::instance().load_all_modules();
}

FFI_EXPORT int bridge_db_update(int32_t record_id, int32_t payload) {
    auto func = ModuleBridge::instance().get_db_update();
    if (!func) return -1; // Database module or method not initialized
    
    // Direct compilation jump execution. Zero overhead.
    return func(record_id, payload);
}