import 'mobile_helper.dart' if (dart.library.html) 'web_helper.dart' as helper;

Future<void> sendToGoogleSheets(String webhookUrl, String payload) async {
  await helper.postToSheets(webhookUrl, payload);
}
