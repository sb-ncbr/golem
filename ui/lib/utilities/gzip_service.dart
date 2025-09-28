import 'dart:async';
// TODO: migrate away from dart:html
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class GZipService {
  static GZipService? _instance;

  GZipService._internal() {
    _initWorker();
  }

  static GZipService get instance {
    _instance ??= GZipService._internal();
    return _instance!;
  }

  html.Worker? _worker;
  final Map<String, Completer<Uint8List>> _completers = {};

  /// Decompresses data using gzip algorithm
  Future<Uint8List> decompress(Uint8List compressedData) async {
    final completer = Completer<Uint8List>();
    final id = 'req_${UniqueKey()}';

    _completers[id] = completer;

    if (_worker == null) {
      await _initWorker();
      if (_worker == null) {
        completer.completeError('Worker not initialized');
        return completer.future;
      }
    }

    _worker!.postMessage({
      'id': id,
      'data': compressedData,
    }, [
      compressedData.buffer
    ]);

    return completer.future;
  }

  Future<void> _initWorker() async {
    try {
      _worker = html.Worker('worker.js');
      _worker!.onMessage.listen(_handleMessage);
      _worker!.onError.listen(_handleError);
    } catch (e) {
      debugPrint('Failed to initialize worker: $e');
    }
  }

  void _handleMessage(html.MessageEvent event) {
    final data = event.data;
    final id = data['id'];
    final completer = _completers[id];

    if (completer != null) {
      if (data['success'] == true) {
        completer.complete(data['data']);
      } else {
        completer.completeError(data['error'] ?? 'Unknown error');
      }
      _completers.remove(id);
    }
  }

  void _handleError(html.Event event) {
    final errorEvent = event as html.ErrorEvent;
    _completers.forEach((id, completer) {
      if (!completer.isCompleted) {
        completer.completeError('Worker error: ${errorEvent.message}');
      }
    });
    _completers.clear();
  }
}
