import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> postToSheets(String webhookUrl, String payload) async {
  try {
    // ignore: unused_local_variable
    final response = await web.window
        .fetch(
          webhookUrl.toJS,
          web.RequestInit(
            method: 'POST',
            mode: 'no-cors',
            headers: web.Headers()..append('Content-Type', 'text/plain'),
            body: payload.toJS,
          ),
        )
        .toDart;
    // In no-cors mode, response.type is 'opaque' and status is 0,
    // which is expected. The request was sent successfully.
  } catch (_) {}
}
