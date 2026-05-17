import 'dart:ffi';
import 'dart:ui' as ui;
import 'package:example/bindings/parmesan_bindings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mandelbrot_controller.dart';

void _initFFI() {
  final bridgeInitialize = nativeLib
      .lookupFunction<Bool Function(), bool Function()>('bridge_initialize');
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
      create: (_) => MandelbrotController()..render(),
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
                builder: (_, computeTime, _) => Text(
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
                  builder: (_, state, _) {
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
                      builder: (_, iterations, _) => ElevatedButton.icon(
                        onPressed: () => context.read<MandelbrotController>().increaseIterations(),
                        icon: const Icon(Icons.add),
                        label: Text('Iterations ($iterations)'),
                      ),
                    ),
                    Selector<MandelbrotController, int>(
                      selector: (_, c) => c.maxIterations,
                      builder: (_, iterations, _) => ElevatedButton.icon(
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
