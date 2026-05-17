import 'dart:ffi';

// Auto-generated FFI bindings by parmesan_cli
// Do not edit manually. Run 'parmesan generate:bindings' to regenerate.

final DynamicLibrary nativeLib = DynamicLibrary.open('example.exe');

// === Module: mandelbrot ===

typedef ParmesanMandelbrotModuleProcessC = Int32 Function(Int32);
typedef ParmesanMandelbrotModuleProcessDart = int Function(int);

final ParmesanMandelbrotModuleProcessDart parmesanMandelbrotModuleProcess = nativeLib
    .lookupFunction<ParmesanMandelbrotModuleProcessC, ParmesanMandelbrotModuleProcessDart>(
        'parmesan_mandelbrot_module_process',
    );

typedef ParmesanMandelbrotComputeMandelbrotC = Void Function(Pointer<Uint8>, Int32, Int32, Double, Double, Double, Int32);
typedef ParmesanMandelbrotComputeMandelbrotDart = void Function(Pointer<Uint8>, int, int, double, double, double, int);

final ParmesanMandelbrotComputeMandelbrotDart parmesanMandelbrotComputeMandelbrot = nativeLib
    .lookupFunction<ParmesanMandelbrotComputeMandelbrotC, ParmesanMandelbrotComputeMandelbrotDart>(
        'parmesan_mandelbrot_compute_mandelbrot',
    );

