#ifndef MANDELBROT_H
#define MANDELBROT_H

#if defined(_WIN32)
    #define MODULE_EXPORT extern "C" __declspec(dllexport)
#else
    #define MODULE_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

MODULE_EXPORT int32_t module_process(int32_t input);

MODULE_EXPORT void compute_mandelbrot(
    uint8_t* buffer,
    int width,
    int height,
    double center_x,
    double center_y,
    double zoom,
    int max_iterations
);

#ifdef __cplusplus
}
#endif

#endif // MANDELBROT_H
