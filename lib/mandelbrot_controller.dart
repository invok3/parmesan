import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

typedef BridgeComputeMandelbrotDart = void Function(
    Pointer<Uint8> buffer,
    int width,
    int height,
    double centerX,
    double centerY,
    double zoom,
    int maxIterations,
);

class MandelbrotController extends ChangeNotifier {
  final BridgeComputeMandelbrotDart _computeFn;

  MandelbrotController(this._computeFn);

  double centerX = -0.5;
  double centerY = 0.0;
  double zoom = 1.0;
  int maxIterations = 100;

  ui.Image? renderedImage;
  String computeTime = '';
  bool isComputing = false;

  Offset? _dragStart;
  double? _dragStartCenterX;
  double? _dragStartCenterY;

  Future<void> render({int width = 800, int height = 600}) async {
    isComputing = true;
    notifyListeners();

    final buffer = calloc<Uint8>(width * height * 4);

    final sw = Stopwatch()..start();
    _computeFn(
      buffer,
      width,
      height,
      centerX,
      centerY,
      zoom,
      maxIterations,
    );
    sw.stop();

    final pixels = Uint8List.fromList(
        List.generate(width * height * 4, (i) => buffer[i]));
    calloc.free(buffer);

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (image) => completer.complete(image),
    );
    final image = await completer.future;

    renderedImage = image;
    computeTime = '${sw.elapsedMilliseconds}ms';
    isComputing = false;
    notifyListeners();
  }

  void zoomIn() {
    zoom *= 2.0;
    notifyListeners();
    render();
  }

  void zoomOut() {
    zoom /= 2.0;
    notifyListeners();
    render();
  }

  void resetView() {
    centerX = -0.5;
    centerY = 0.0;
    zoom = 1.0;
    notifyListeners();
    render();
  }

  void increaseIterations() {
    maxIterations = (maxIterations + 50).clamp(50, 1000);
    notifyListeners();
    render();
  }

  void decreaseIterations() {
    maxIterations = (maxIterations - 50).clamp(50, 1000);
    notifyListeners();
    render();
  }

  void onPanStart(Offset position) {
    _dragStart = position;
    _dragStartCenterX = centerX;
    _dragStartCenterY = centerY;
  }

  void onPanUpdate(Offset position) {
    if (_dragStart == null) return;
    final dx = position.dx - _dragStart!.dx;
    final dy = position.dy - _dragStart!.dy;
    final scale = 4.0 / zoom;
    centerX = _dragStartCenterX! - dx * scale / 800;
    centerY = _dragStartCenterY! - dy * scale / 600;
    notifyListeners();
  }

  void onPanEnd() {
    _dragStart = null;
    render();
  }
}
