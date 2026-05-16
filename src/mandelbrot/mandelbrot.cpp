#include "mandelbrot/mandelbrot.h"
#include <cmath>

static void hsv_to_rgb(double h, double s, double v, uint8_t* r, uint8_t* g, uint8_t* b) {
    double c = v * s;
    double x = c * (1.0 - fabs(fmod(h / 60.0, 2.0) - 1.0));
    double m = v - c;

    double r1 = 0, g1 = 0, b1 = 0;
    if (h < 60)       { r1 = c; g1 = x; b1 = 0; }
    else if (h < 120) { r1 = x; g1 = c; b1 = 0; }
    else if (h < 180) { r1 = 0; g1 = c; b1 = x; }
    else if (h < 240) { r1 = 0; g1 = x; b1 = c; }
    else if (h < 300) { r1 = x; g1 = 0; b1 = c; }
    else              { r1 = c; g1 = 0; b1 = x; }

    *r = (uint8_t)((r1 + m) * 255);
    *g = (uint8_t)((g1 + m) * 255);
    *b = (uint8_t)((b1 + m) * 255);
}

MODULE_EXPORT void compute_mandelbrot(
    uint8_t* buffer,
    int width,
    int height,
    double center_x,
    double center_y,
    double zoom,
    int max_iterations
) {
    double scale = 4.0 / zoom;

    for (int py = 0; py < height; py++) {
        for (int px = 0; px < width; px++) {
            double x0 = center_x + scale * (px - width / 2.0) / width;
            double y0 = center_y + scale * (py - height / 2.0) / height;

            double x = 0.0;
            double y = 0.0;
            int iteration = 0;
            double x2 = 0.0;
            double y2 = 0.0;

            while (x2 + y2 <= 4.0 && iteration < max_iterations) {
                y = 2.0 * x * y + y0;
                x = x2 - y2 + x0;
                x2 = x * x;
                y2 = y * y;
                iteration++;
            }

            int idx = (py * width + px) * 4;

            if (iteration == max_iterations) {
                buffer[idx]     = 0;
                buffer[idx + 1] = 0;
                buffer[idx + 2] = 0;
            } else {
                double hue = fmod(iteration * 3.5, 360.0);
                double sat = 0.8;
                double val = (iteration < max_iterations) ? 1.0 : 0.0;
                hsv_to_rgb(hue, sat, val,
                    &buffer[idx],
                    &buffer[idx + 1],
                    &buffer[idx + 2]);
            }

            buffer[idx + 3] = 255; // Alpha
        }
    }
}
