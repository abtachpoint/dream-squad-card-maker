import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CutoutService {
  Future<String> removeBackground(
    String sourcePath, {
    bool person = true,
  }) async {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw const CutoutServiceException('Image file not found.');
    }

    final cache = await getTemporaryDirectory();
    final outputPath = '${cache.path}/cutout_${DateTime.now().microsecondsSinceEpoch}.png';

    if (person && Platform.isAndroid) {
      return _removePersonBackground(sourcePath, outputPath);
    }

    return _removeSimpleBackground(sourcePath, outputPath);
  }

  Future<String> _removePersonBackground(String sourcePath, String outputPath) async {
    final segmenter = SelfieSegmenter(
      mode: SegmenterMode.single,
      enableRawSizeMask: true,
    );

    try {
      final mask = await segmenter.processImage(InputImage.fromFilePath(sourcePath));
      if (mask == null || mask.confidences.isEmpty) {
        throw const CutoutServiceException('No person could be detected in this photo.');
      }

      final task = _PersonCutoutTask(
        sourcePath: sourcePath,
        outputPath: outputPath,
        maskWidth: mask.width,
        maskHeight: mask.height,
        confidences: mask.confidences,
      );
      final ok = await Isolate.run(() => _applyPersonMask(task));
      if (!ok) {
        throw const CutoutServiceException('Couldn’t create a transparent player cutout.');
      }
      return outputPath;
    } on CutoutServiceException {
      rethrow;
    } catch (error) {
      throw CutoutServiceException('Background removal failed: $error');
    } finally {
      await segmenter.close();
    }
  }

  Future<String> _removeSimpleBackground(String sourcePath, String outputPath) async {
    try {
      final ok = await Isolate.run(
        () => _applyEdgeBackgroundRemoval(
          _SimpleCutoutTask(sourcePath: sourcePath, outputPath: outputPath),
        ),
      );
      if (!ok) {
        throw const CutoutServiceException('Couldn’t remove this background. Try cropping the image first.');
      }
      return outputPath;
    } on CutoutServiceException {
      rethrow;
    } catch (error) {
      throw CutoutServiceException('Background removal failed: $error');
    }
  }
}

class _PersonCutoutTask {
  const _PersonCutoutTask({
    required this.sourcePath,
    required this.outputPath,
    required this.maskWidth,
    required this.maskHeight,
    required this.confidences,
  });

  final String sourcePath;
  final String outputPath;
  final int maskWidth;
  final int maskHeight;
  final List<double> confidences;
}

class _SimpleCutoutTask {
  const _SimpleCutoutTask({required this.sourcePath, required this.outputPath});
  final String sourcePath;
  final String outputPath;
}


img.Image _bounded(img.Image source) {
  const maxSide = 2000;
  if (source.width <= maxSide && source.height <= maxSide) return source;
  if (source.width >= source.height) {
    return img.copyResize(source, width: maxSide, interpolation: img.Interpolation.cubic);
  }
  return img.copyResize(source, height: maxSide, interpolation: img.Interpolation.cubic);
}

bool _applyPersonMask(_PersonCutoutTask task) {
  final bytes = File(task.sourcePath).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return false;
  final source = _bounded(img.bakeOrientation(decoded));
  final out = img.Image(width: source.width, height: source.height, numChannels: 4);

  final mw = math.max(1, task.maskWidth);
  final mh = math.max(1, task.maskHeight);
  if (task.confidences.length < mw * mh) return false;

  for (var y = 0; y < source.height; y++) {
    final my = math.min(mh - 1, (y * mh / source.height).floor());
    for (var x = 0; x < source.width; x++) {
      final mx = math.min(mw - 1, (x * mw / source.width).floor());
      final confidence = task.confidences[my * mw + mx].clamp(0.0, 1.0);
      final alpha = _softAlpha(confidence);
      final p = source.getPixel(x, y);
      out.setPixelRgba(x, y, p.r, p.g, p.b, alpha);
    }
  }

  File(task.outputPath).writeAsBytesSync(img.encodePng(out, level: 6));
  return true;
}

int _softAlpha(double confidence) {
  const low = 0.20;
  const high = 0.78;
  if (confidence <= low) return 0;
  if (confidence >= high) return 255;
  var t = (confidence - low) / (high - low);
  t = t * t * (3 - 2 * t); // smoothstep for cleaner hair/edge transitions.
  return (t * 255).round();
}

bool _applyEdgeBackgroundRemoval(_SimpleCutoutTask task) {
  final bytes = File(task.sourcePath).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return false;
  final source = _bounded(img.bakeOrientation(decoded));

  // Preserve a PNG that already contains useful transparency.
  var transparentSamples = 0;
  for (final point in [
    (0, 0),
    (source.width - 1, 0),
    (0, source.height - 1),
    (source.width - 1, source.height - 1),
  ]) {
    if (source.getPixel(point.$1, point.$2).a < 250) transparentSamples++;
  }
  if (transparentSamples >= 2) {
    File(task.outputPath).writeAsBytesSync(img.encodePng(source));
    return true;
  }

  final corners = [
    source.getPixel(0, 0),
    source.getPixel(source.width - 1, 0),
    source.getPixel(0, source.height - 1),
    source.getPixel(source.width - 1, source.height - 1),
  ];
  final bg = (
    corners.map((p) => p.r.toDouble()).reduce((a, b) => a + b) / corners.length,
    corners.map((p) => p.g.toDouble()).reduce((a, b) => a + b) / corners.length,
    corners.map((p) => p.b.toDouble()).reduce((a, b) => a + b) / corners.length,
  );

  final width = source.width;
  final height = source.height;
  final visited = List<bool>.filled(width * height, false);
  final remove = List<bool>.filled(width * height, false);
  final queue = Queue<int>();

  bool similar(int x, int y) {
    final p = source.getPixel(x, y);
    final dr = p.r - bg.$1;
    final dg = p.g - bg.$2;
    final db = p.b - bg.$3;
    return dr * dr + dg * dg + db * db <= 58 * 58;
  }

  void seed(int x, int y) {
    final idx = y * width + x;
    if (!visited[idx] && similar(x, y)) {
      visited[idx] = true;
      queue.add(idx);
    }
  }

  for (var x = 0; x < width; x++) {
    seed(x, 0);
    seed(x, height - 1);
  }
  for (var y = 0; y < height; y++) {
    seed(0, y);
    seed(width - 1, y);
  }

  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  while (queue.isNotEmpty) {
    final idx = queue.removeFirst();
    remove[idx] = true;
    final x = idx % width;
    final y = idx ~/ width;
    for (final d in dirs) {
      final nx = x + d.$1;
      final ny = y + d.$2;
      if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
      final ni = ny * width + nx;
      if (visited[ni]) continue;
      visited[ni] = true;
      if (similar(nx, ny)) queue.add(ni);
    }
  }

  final out = img.Image(width: width, height: height, numChannels: 4);
  var removedCount = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final idx = y * width + x;
      final p = source.getPixel(x, y);
      final alpha = remove[idx] ? 0 : 255;
      if (alpha == 0) removedCount++;
      out.setPixelRgba(x, y, p.r, p.g, p.b, alpha);
    }
  }

  if (removedCount < (width * height * 0.01)) return false;
  File(task.outputPath).writeAsBytesSync(img.encodePng(out, level: 6));
  return true;
}

class CutoutServiceException implements Exception {
  const CutoutServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

final cutoutService = CutoutService();
