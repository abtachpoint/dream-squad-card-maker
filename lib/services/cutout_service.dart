import 'dart:io';

import 'package:native_cutout/native_cutout.dart';

class CutoutService {
  bool _warming = false;
  bool _ready = false;

  bool get ready => _ready;

  Future<bool> warmUp() async {
    if (!Platform.isAndroid) {
      _ready = true;
      return true;
    }
    if (_ready) return true;
    if (_warming) {
      for (var i = 0; i < 80 && _warming; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return _ready;
    }
    _warming = true;
    try {
      final available = await NativeCutout.isModelAvailable();
      _ready = available || await NativeCutout.downloadModel();
      return _ready;
    } catch (_) {
      _ready = false;
      return false;
    } finally {
      _warming = false;
    }
  }

  Future<String> removeBackground(String sourcePath) async {
    if (sourcePath.isEmpty || !File(sourcePath).existsSync()) {
      throw const CutoutServiceException('Image file not found.');
    }
    if (Platform.isAndroid && !await warmUp()) {
      throw const CutoutServiceException('Background removal model could not be downloaded. Check internet and try again.');
    }

    final result = await NativeCutout.removeBackground(
      sourcePath,
      options: const CutoutOptions(
        cropToSubject: true,
        writeToCache: true,
      ),
    );

    return switch (result) {
      CutoutFileSuccess(:final path) => path,
      CutoutBytesSuccess() => throw const CutoutServiceException('Unexpected background removal output.'),
      CutoutFailure(:final message) => throw CutoutServiceException(message),
    };
  }
}

class CutoutServiceException implements Exception {
  const CutoutServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

final cutoutService = CutoutService();
