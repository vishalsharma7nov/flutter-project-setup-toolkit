import 'dart:convert';
import 'dart:io';

class StudioHttp {
  static Future<Map<String, dynamic>> readJsonBody(HttpRequest request) async {
    final raw = await utf8.decoder.bind(request).join();
    if (raw.trim().isEmpty) {
      return {};
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static void respondJson(
    HttpResponse response,
    int status,
    Map<String, dynamic> body,
  ) {
    response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
  }

  static void respondHtml(HttpResponse response, String html) {
    response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..headers.set('Cache-Control', 'no-store, no-cache, must-revalidate')
      ..headers.set('Pragma', 'no-cache')
      ..write(html);
  }
}
