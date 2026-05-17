# Parmesan

CLI tool to scaffold Flutter + C++ FFI projects.

## Features

- **Module management** — Add C++ modules with auto-generated headers, bridge code, and Dart FFI bindings
- **Cross-platform builds** — Add Windows and Linux platform support with CMake configuration (macOS not supported)
- **Automatic binding generation** — Parse C++ headers and generate `dart:ffi` bindings

## Installation

```sh
dart pub global activate parmesan
```

## Prerequisites

- Dart SDK >=3.11.5
- Flutter SDK
- C++ compiler (MSVC for Windows, GCC/Clang for Linux)
- CMake

## Platform Support

| Platform | Supported | Notes |
|----------|-----------|-------|
| Windows  | Yes       | MSVC compiler, CMake |
| Linux    | Yes       | GCC/Clang compiler, CMake |
| macOS    | No        | macOS requires C++ code to be built within Xcode IDE. Parmesan's CLI-based workflow is not compatible with macOS's build requirements. |

## Usage

### Add a C++ module

```sh
parmesan add:module my_module --functions "int32_t compute(int32_t x),void process()"
```

Omit `--functions` to enter function signatures interactively.

Options:
- `-f, --functions` — Comma-separated function signatures
- `-p, --path` — Path to the Parmesan project (default: current directory)

> **Convention:** All functions exposed to Dart must be declared with `MODULE_EXPORT` in the module's header file (`.h`). The `generate:bindings` command only scans header files.

### Add platform support

```sh
parmesan add:platform windows
parmesan add:platform linux
parmesan add:platform all
```

Options:
- `-p, --path` — Path to the Parmesan project (default: current directory)

### Generate Dart FFI bindings

Scans all modules in `src/`, regenerates bridge files, and creates a single Dart bindings file.

```sh
parmesan generate:bindings
parmesan generate:bindings -l myapp.exe
```

Options:
- `-l, --library` — Native library name (auto-detected from pubspec.yaml)
- `-p, --path` — Path to the Parmesan project (default: current directory)

## Running Tests

```sh
dart test
```

## License

MIT
