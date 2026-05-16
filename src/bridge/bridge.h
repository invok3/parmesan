#pragma once
#include <string>
#include <windows.h>
#include <stdint.h>

#if defined(_WIN32)
    #define FFI_EXPORT extern "C" __declspec(dllexport)
#else
    #define FFI_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif

// Predefined function signature for the mandelbrot computation
typedef void (*MandelbrotFunc)(uint8_t* buffer, int width, int height, double center_x, double center_y, double zoom, int max_iterations);

class ModuleBridge {
private:
    HMODULE mandelbrot_handle = nullptr;

    // Cached function pointers to avoid calling GetProcAddress repeatedly
    MandelbrotFunc mandelbrot_ptr = nullptr;

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
    MandelbrotFunc get_mandelbrot() const { return mandelbrot_ptr; }
};

// Purely type-safe, explicit FFI entry points for Flutter
FFI_EXPORT bool bridge_initialize();
FFI_EXPORT void bridge_compute_mandelbrot(uint8_t* buffer, int width, int height, double center_x, double center_y, double zoom, int max_iterations);