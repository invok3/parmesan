#pragma once
#include <stdint.h>

#if defined(_WIN32)
    #define MODULE_EXPORT extern "C" __declspec(dllexport)
#else
    #define MODULE_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif

MODULE_EXPORT void compute_mandelbrot(
    uint8_t* buffer,
    int width,
    int height,
    double center_x,
    double center_y,
    double zoom,
    int max_iterations
);
