import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

void main() async {
  const apiKey = 'AIzaSyAWCVz32HQeRVog77JX6xwa-4Pxr4RvFR0';
  final response = await http.post(
    Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash?key=$apiKey'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': 'Hello'}
          ]
        }
      ]
    }),
  );
  debugPrint('STATUS: ${response.statusCode}');
  debugPrint('BODY: ${response.body}');
}
