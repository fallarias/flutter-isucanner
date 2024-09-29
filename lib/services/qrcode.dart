import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../variables/ip_address.dart';

class QRService {

  Future<void> sendQRDataToBackend(dynamic data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) {
      print('Token is null. Please login first.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$ipaddress/scanned_data'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'scanned_data': data is List ? data : [data], // Convert to array if not already
        }),
      );

      if (response.statusCode == 200) {
        print('Data successfully sent to the backend.');
      } else {
        print('Failed to send data. Error: ${response.body}');
      }
    } catch (e) {
      print('Error while sending data: $e');
    }
  }
}
