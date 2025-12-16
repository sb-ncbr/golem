import 'package:web/web.dart' as web;
import 'dart:js_interop' as js;

void downloadFile(dynamic content, String contentType, String filename) {
  final finalBlob = web.Blob([content] as js.JSArray<web.BlobPart>,
      web.BlobPropertyBag(type: contentType));
  final url = web.URL.createObjectURL(finalBlob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);
}
