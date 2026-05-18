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
typedef int32_t (*mandelbrot_module_process_fn)(int32_t input);
typedef void (*mandelbrot_compute_mandelbrot_fn)(uint8_t* buffer, int width, int height, double center_x, double center_y, double zoom, int max_iterations);

class ModuleBridge {
public:
    static ModuleBridge& instance();

    bool load_all_modules();
    void unload_all_modules();

    mandelbrot_module_process_fn get_mandelbrot_module_process();

    mandelbrot_compute_mandelbrot_fn get_mandelbrot_compute_mandelbrot();

private:
    ModuleBridge();
    ~ModuleBridge();
    ModuleBridge(const ModuleBridge&) = delete;
    ModuleBridge& operator=(const ModuleBridge&) = delete;

    ModuleHandle load_module(const std::string& name);
    void* resolve_symbol(ModuleHandle handle, const std::string& symbol);
    void unload_module(ModuleHandle handle);

    ModuleHandle mandelbrot_handle;
};

// FFI entry points
FFI_EXPORT int bridge_initialize();

    FFI_EXPORT int32_t parmesan_mandelbrot_module_process(int32_t input);

    FFI_EXPORT void parmesan_mandelbrot_compute_mandelbrot(uint8_t* buffer, int width, int height, double center_x, double center_y, double zoom, int max_iterations);

#endif // BRIDGE_H
