import 'dart:ffi';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mandelbrot_controller.dart';

typedef BridgeInitializeC = Bool Function();
typedef BridgeInitializeDart = bool Function();

typedef BridgeComputeMandelbrotC = Void Function(
    Pointer<Uint8> buffer,
    Int32 width,
    Int32 height,
    Double centerX,
    Double centerY,
    Double zoom,
    Int32 maxIterations,
);
typedef BridgeComputeMandelbrotDart = void Function(
    Pointer<Uint8> buffer,
    int width,
    int height,
    double centerX,
    double centerY,
    double zoom,
    int maxIterations,
);

late final BridgeComputeMandelbrotDart bridgeComputeMandelbrot;

void _initFFI() {
  final DynamicLibrary nativeLib = DynamicLibrary.open('parmesan.exe');

  final bridgeInitialize = nativeLib
      .lookupFunction<BridgeInitializeC, BridgeInitializeDart>(
          'bridge_initialize');

  bridgeComputeMandelbrot = nativeLib
      .lookupFunction<BridgeComputeMandelbrotC, BridgeComputeMandelbrotDart>(
          'bridge_compute_mandelbrot');

  bridgeInitialize();
}

void main() {
  _initFFI();
  runApp(const ParmesanApp());
}

class ParmesanApp extends StatelessWidget {
  const ParmesanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MandelbrotController(bridgeComputeMandelbrot)..render(),
      child: MaterialApp(
        title: 'Parmesan - Mandelbrot FFI Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MandelbrotViewer(),
      ),
    );
  }
}

class MandelbrotViewer extends StatelessWidget {
  const MandelbrotViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Mandelbrot Set - C++ FFI Demo'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Selector<MandelbrotController, String>(
                selector: (_, c) => c.computeTime,
                builder: (_, computeTime, __) => Text(
                  computeTime,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onPanStart: (details) {
          context.read<MandelbrotController>().onPanStart(details.localPosition);
        },
        onPanUpdate: (details) {
          context.read<MandelbrotController>().onPanUpdate(details.localPosition);
        },
        onPanEnd: (_) {
          context.read<MandelbrotController>().onPanEnd();
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Selector<MandelbrotController, (bool, ui.Image?)>(
                  selector: (_, c) => (c.isComputing, c.renderedImage),
                  builder: (_, state, __) {
                    final (isComputing, renderedImage) = state;
                    if (isComputing) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (renderedImage != null) {
                      return RawImage(
                        image: renderedImage,
                        fit: BoxFit.contain,
                      );
                    }
                    return const Text('Rendering...');
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.read<MandelbrotController>().zoomIn(),
                      icon: const Icon(Icons.zoom_in),
                      label: const Text('Zoom In'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.read<MandelbrotController>().zoomOut(),
                      icon: const Icon(Icons.zoom_out),
                      label: const Text('Zoom Out'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.read<MandelbrotController>().resetView(),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset'),
                    ),
                    Selector<MandelbrotController, int>(
                      selector: (_, c) => c.maxIterations,
                      builder: (_, iterations, __) => ElevatedButton.icon(
                        onPressed: () => context.read<MandelbrotController>().increaseIterations(),
                        icon: const Icon(Icons.add),
                        label: Text('Iterations ($iterations)'),
                      ),
                    ),
                    Selector<MandelbrotController, int>(
                      selector: (_, c) => c.maxIterations,
                      builder: (_, iterations, __) => ElevatedButton.icon(
                        onPressed: () => context.read<MandelbrotController>().decreaseIterations(),
                        icon: const Icon(Icons.remove),
                        label: Text('Iterations ($iterations)'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
