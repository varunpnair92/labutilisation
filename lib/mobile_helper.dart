import 'package:http/http.dart' as http;

Future<void> postToSheets(String webhookUrl, String payload) async {
  final response = await http
      .post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'text/plain'},
        body: payload,
      )
      .timeout(const Duration(seconds: 15));
  if (response.statusCode != 200 && response.statusCode != 302) {
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
}
