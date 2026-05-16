#include "bridge.h"
#include <iostream>

bool ModuleBridge::load_all_modules() {
    // 1st) Hardcoded loading of the known "dbHandler" module
    // We expect the module subfolder to live next to our main executable

    // Load mandelbrot module
    if (mandelbrot_handle == nullptr) {
        mandelbrot_handle = LoadLibraryA("modules\\mandelbrot.dll");
        if (!mandelbrot_handle) {
            std::cerr << "Failed to load mandelbrot.dll" << std::endl;
            return false;
        }

        mandelbrot_ptr = (MandelbrotFunc)GetProcAddress(mandelbrot_handle, "compute_mandelbrot");
        if (!mandelbrot_ptr) {
            FreeLibrary(mandelbrot_handle);
            mandelbrot_handle = nullptr;
            return false;
        }
    }

    // Add other modules here (e.g., processing_handle, etc.)
    return true;
}

void ModuleBridge::unload_all() {

    if (mandelbrot_handle) {
        FreeLibrary(mandelbrot_handle);
        mandelbrot_handle = nullptr;
        mandelbrot_ptr = nullptr;
    }
}

// ==========================================
// FFI Glue Code (Direct, Type-Safe)
// ==========================================

FFI_EXPORT bool bridge_initialize() {
    return ModuleBridge::instance().load_all_modules();
}


FFI_EXPORT void bridge_compute_mandelbrot(uint8_t* buffer, int width, int height, double center_x, double center_y, double zoom, int max_iterations) {
    auto func = ModuleBridge::instance().get_mandelbrot();
    if (!func) return; // Mandelbrot module not initialized

    // Direct computation jump. Zero overhead.
    func(buffer, width, height, center_x, center_y, zoom, max_iterations);
}
