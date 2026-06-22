import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/receipt.dart';
import 'auth_service.dart';

class ApiService {
  ApiService(this._auth);

  static const endpoint = String.fromEnvironment('API_BASE_URL');
  final AuthService _auth;

  Future<Receipt> extract({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final json = await _post({
      'action': 'extract',
      'image_base64': base64Encode(imageBytes),
      'mime_type': mimeType,
    });
    return Receipt.fromJson(json['transaction'] as Map<String, dynamic>);
  }

  Future<Receipt> save({
    required Receipt receipt,
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final json = await _post({
      'action': 'save',
      'transaction': receipt.toJson(),
      'image_base64': base64Encode(imageBytes),
      'mime_type': mimeType,
    });
    return Receipt.fromJson(json['receipt'] as Map<String, dynamic>);
  }

  Future<List<Receipt>> list() async {
    final json = await _post({'action': 'list'});
    return (json['receipts'] as List<dynamic>)
        .map((item) => Receipt.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    if (endpoint.isEmpty) throw StateError('This APK is missing API_BASE_URL.');
    body['id_token'] = await _auth.idToken();
    final client = http.Client();
    late http.Response response;
    try {
      final request = http.Request('POST', Uri.parse(endpoint))
        ..followRedirects = false
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
      response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 60)),
      );

      // Apps Script ContentService returns its JSON through a temporary 302
      // googleusercontent URL. Dart does not follow POST redirects for us.
      if ({301, 302, 303}.contains(response.statusCode)) {
        final location = response.headers['location'];
        if (location == null) {
          throw StateError(
            'The hishabAI service returned an invalid redirect.',
          );
        }
        final redirectUri = Uri.parse(endpoint).resolve(location);
        response = await client
            .get(redirectUri)
            .timeout(const Duration(seconds: 60));
      }
    } finally {
      client.close();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'The hishabAI service is unavailable (${response.statusCode}).',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['ok'] != true) {
      throw StateError('${json['error'] ?? 'Request failed.'}');
    }
    return json;
  }
}
