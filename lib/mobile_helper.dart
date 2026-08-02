import 'package:http/http.dart' as http;

Future<void> postToSheets(String webhookUrl, String payload) async {
  try {
    await http
        .post(
          Uri.parse(webhookUrl),
          headers: {'Content-Type': 'text/plain'},
          body: payload,
        )
        .timeout(const Duration(seconds: 4));
  } catch (_) {}
}
