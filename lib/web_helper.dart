import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> postToSheets(String webhookUrl, String payload) async {
  try {
    web.window.fetch(
      webhookUrl.toJS,
      web.RequestInit(
        method: 'POST',
        mode: 'no-cors',
        headers: web.Headers()..append('Content-Type', 'text/plain'),
        body: payload.toJS,
      ),
    );
  } catch (_) {}
}
