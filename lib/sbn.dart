import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pettebook/datafetching.dart';
import 'package:flutter/foundation.dart';

Future<String?> getSbnAccessToken(String consumerKey, String consumerSecret) async {
  final String tokenUrl = 'https://api.iccu.sbn.it/oauth2/token';
  
  // 1. Combine and Base64 encode the credentials
  final String credentials = '$consumerKey:$consumerSecret';
  final String base64Credentials = base64Encode(utf8.encode(credentials));

  try {
    // 2. Make the POST request
    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {
        'Authorization': 'Basic $base64Credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      // 3. Extract and return the token
      return data['access_token']; 
    } else {
      print('Failed to get token: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error during token generation: $e');
    return null;
  }
}

class SbnOrchestrator {
	static String? _cachedToken;
	static DateTime? _tokenExpiry;

	static Future<String?> _getValidToken() async {
		final now = DateTime.now();

		if (_cachedToken != null && _tokenExpiry != null) {
			if (_tokenExpiry!.difference(now).inMinutes > 5) {
				debugPrint('Using cached SBN token.');
				return _cachedToken;
			}
		}

		debugPrint('Fetching new SBN token...');
		final clientId = dotenv.env['SBN_CLIENT_ID'] ?? '';
		final clientSecret = dotenv.env['SBN_CLIENT_SECRET'] ?? '';

		if (clientId.isEmpty || clientSecret.isEmpty) {
			debugPrint('Error: Missing SBN credentials in .env file');
			return null;
		}

		final newToken = await getSbnAccessToken(clientId, clientSecret);

		if (newToken != null) {
			_cachedToken = newToken;
			_tokenExpiry = now.add(const Duration(minutes: 55));

		}

		return _cachedToken;
	}
	

	static Future<List<Map<String, dynamic>>> handleSearch(String query) async {
		if (query.isEmpty) return [];

		final token = await _getValidToken();

		if (token == null) {
			debugPrint('Failed to obtain SBN token. Search aborted.');
			return [];
		}

		return await sbnSearchByTitle(query, token);
	}
}
			
