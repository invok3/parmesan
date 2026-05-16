# Parmesan

A cross-platform application architecture that uses **Flutter** as the front-end UI layer and **C++** as the high-performance back-end, connected via **Dart FFI** (Foreign Function Interface).

This project demonstrates the pattern with a **Mandelbrot set fractal renderer** — Flutter handles the UI (zoom, pan, controls) while C++ does the heavy pixel computation.

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Flutter (Dart)                     │
│                     UI Layer                         │
│                                                      │
│  ┌───────────────────────────────────────────────┐  │
│  │              Dart FFI Bindings                 │  │
│  │   bridge_initialize()                         │  │
│  │   bridge_compute_mandelbrot(...)              │  │
│  └──────────────────────┬────────────────────────┘  │
└─────────────────────────┼───────────────────────────┘
                          │ FFI Boundary
┌─────────────────────────┼───────────────────────────┐
│              C++ Bridge Layer                        │
│                                                      │
│  ┌─────────────────────────────────────────────┐    │
│  │           bridge.cpp / bridge.h              │    │
│  │  ┌───────────────────────────────────────┐  │    │
│  │  │          ModuleBridge (Singleton)      │  │    │
│  │  │  - load_all_modules()                  │  │    │
│  │  │  - cache function pointers             │  │    │
│  │  │  - FFI entry points                    │  │    │
│  │  └───────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────┘    │
│                                                      │
│  ┌─────────────────────────────────────────────┐    │
│  │         Dynamic Module Loading               │    │
│  │  modules/mandelbrot.dll  (Windows)           │    │
│  │  modules/libmandelbrot.so  (Linux)           │    │
│  │  modules/libmandelbrot.dylib (macOS)         │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

## Project Structure

```
parmesan/
├── lib/                          # Flutter/Dart source
│   ├── main.dart                 # App entry point, FFI bindings, UI
│   └── mandelbrot_controller.dart # State management (ChangeNotifier)
├── src/                          # C++ back-end source
│   ├── bridge/                   # Core FFI bridge (compiled into main executable)
│   │   ├── bridge.h              # Bridge header: FFI exports, ModuleBridge class
│   │   └── bridge.cpp            # Bridge implementation: module loading, FFI entry points
│   └── mandelbrot/               # Mandelbrot computation module (compiled to dynamic library)
│       ├── mandelbrot.h          # Module header: compute_mandelbrot export
│       └── mandelbrot.cpp        # Mandelbrot set computation with HSV coloring
├── windows/
│   └── runner/
│       └── CMakeLists.txt        # Windows build: links bridge, builds modules as DLLs
├── linux/                        # Linux build configuration (future)
├── macos/                        # macOS build configuration (future)
└── README.md
```

## How It Works

### 1. The Bridge Pattern

The `ModuleBridge` singleton in `src/bridge/` acts as the central orchestrator:

- **Compiled directly into the main executable** (not a separate DLL)
- Loads platform-specific dynamic libraries at runtime (`LoadLibraryA` on Windows, `dlopen` on POSIX)
- Caches function pointers from loaded modules to avoid repeated `GetProcAddress`/`dlsym` calls
- Exposes clean, type-safe `extern "C"` FFI entry points for Dart to call

### 2. Module System

Each back-end feature is a separate C++ module compiled as a platform-specific dynamic library:

| Platform | Extension | Location |
|----------|-----------|----------|
| Windows  | `.dll`    | `modules/` next to executable |
| Linux    | `.so`     | `modules/` next to executable |
| macOS    | `.dylib`  | `modules/` next to executable |

Modules are loaded by the bridge at application startup via `bridge_initialize()`.

### 3. FFI Communication Flow

```
Dart UI → bridge_initialize() → Bridge loads all modules
Dart UI → bridge_compute_mandelbrot(buffer, width, height, centerX, centerY, zoom, maxIterations)
         → Bridge calls cached function pointer → mandelbrot.dll fills pixel buffer
         → Dart decodes raw RGBA → RawImage widget displays
```

## Use Cases

### When to Use This Architecture

- **Performance-critical applications**: C++ handles computationally intensive tasks while Flutter provides a beautiful UI
- **Code reuse across platforms**: Share C++ business logic across Flutter mobile, desktop, and web (via WASM)
- **Legacy C++ integration**: Wrap existing C++ codebases with a modern Flutter front-end
- **Modular back-end**: Independent modules can be updated/replaced without recompiling the main application
- **High-performance data processing**: Fractal rendering, signal processing, image manipulation, etc.

### Example Applications

- Desktop applications with heavy data processing
- Real-time monitoring dashboards
- CAD/CAM tools with computational geometry
- Audio/video processing applications
- Scientific visualization tools

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- C++ compiler (MSVC for Windows, GCC/Clang for Linux/macOS)
- CMake (3.14+)

### Building

#### Windows

```bash
flutter build windows
```

The CMake configuration in `windows/runner/CMakeLists.txt` automatically:
1. Compiles `bridge.cpp` into the main executable
2. Builds each folder under `src/` (except `bridge/`) as a separate DLL into `modules/`

#### Linux / macOS

Configuration for these platforms follows the same pattern. Add corresponding `CMakeLists.txt` files in `linux/` and `macos/` runner directories.

### Running

1. Build the project
2. Ensure the `modules/` directory with compiled DLLs is next to the executable (CMake handles this automatically)
3. Run the Flutter app

## How to Edit This Project

### Adding a New C++ Module

1. **Create the module directory** under `src/`:
   ```
   src/
   └── myNewModule/
       ├── my_new_module.h
       └── my_new_module.cpp
   ```

2. **Export functions with C linkage** in your module:
   ```cpp
   // my_new_module.cpp
   #include <stdint.h>

   extern "C" __declspec(dllexport) int my_function(int32_t input) {
       return input * 2;
   }
   ```

3. **Add the module to the bridge** (`src/bridge/bridge.h`):
   ```cpp
   // Add function pointer typedef
   typedef int (*MyNewFunc)(int32_t input);

   // Add member variables to ModuleBridge
   HMODULE my_new_module_handle = nullptr;
   MyNewFunc my_new_func_ptr = nullptr;

   // Add getter
   MyNewFunc get_my_new_func() const { return my_new_func_ptr; }
   ```

4. **Load the module** (`src/bridge/bridge.cpp`):
   ```cpp
   bool ModuleBridge::load_all_modules() {
       // ... existing module loading ...

       // Load new module
       if (my_new_module_handle == nullptr) {
           my_new_module_handle = LoadLibraryA("modules\\myNewModule.dll");
           if (!my_new_module_handle) return false;

           my_new_func_ptr = (MyNewFunc)GetProcAddress(my_new_module_handle, "my_function");
           if (!my_new_func_ptr) {
               FreeLibrary(my_new_module_handle);
               my_new_module_handle = nullptr;
               return false;
           }
       }

       return true;
   }
   ```

5. **Add an FFI entry point** (`src/bridge/bridge.h`):
   ```cpp
   FFI_EXPORT int bridge_my_new_function(int32_t input);
   ```

6. **Implement the FFI entry point** (`src/bridge/bridge.cpp`):
   ```cpp
   FFI_EXPORT int bridge_my_new_function(int32_t input) {
       auto func = ModuleBridge::instance().get_my_new_func();
       if (!func) return -1;
       return func(input);
   }
   ```

7. **Add Dart FFI bindings** (`lib/main.dart` or a dedicated bindings file):
   ```dart
   import 'dart:ffi';
   import 'package:flutter/material.dart';
   import 'package:provider/provider.dart';

   typedef BridgeMyNewFunctionC = Int32 Function(Int32 input);
   typedef BridgeMyNewFunctionDart = int Function(int input);

   final DynamicLibrary nativeLib = DynamicLibrary.open('parmesan.exe');

   final BridgeMyNewFunctionDart bridgeMyNewFunction = nativeLib
       .lookupFunction<BridgeMyNewFunctionC, BridgeMyNewFunctionDart>(
           'bridge_my_new_function',
       );
   ```

### Modifying an Existing Module

- Edit the C++ source files in `src/<module_name>/`
- Rebuild: `flutter build windows`
- The new DLL will be generated automatically

### Adding Platform Support

1. Create the platform-specific runner directory (e.g., `linux/runner/`)
2. Copy the CMakeLists.txt pattern from `windows/runner/CMakeLists.txt`
3. Update `LoadLibraryA`/`GetProcAddress` calls in `bridge.cpp` to use `dlopen`/`dlsym` for POSIX platforms
4. Update the `FFI_EXPORT` macro (already handles non-Windows platforms)

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Bridge compiled into main executable | No separate DLL to manage for the core FFI layer |
| Modules as separate dynamic libraries | Hot-swappable, independent compilation, smaller main binary |
| Function pointer caching | Zero-overhead calls after initialization |
| Singleton pattern | Single point of module management, prevents duplicate loads |
| `extern "C"` FFI exports | Name stability, no C++ name mangling issues |
| Fail-fast on module load errors | Immediate feedback if a module is missing or malformed |
| Provider for state management | Fine-grained rebuilds, separation of concerns, testable |

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Windows  | Supported | DLL modules, MSVC compilation |
| Linux    | Planned  | SO modules, GCC/Clang |
| macOS    | Planned  | Dylib modules, Clang |
| Android  | Planned  | SO modules, NDK |
| iOS      | Planned  | Static linking (no dynamic libraries on iOS) |

## License

[Add your license here]
