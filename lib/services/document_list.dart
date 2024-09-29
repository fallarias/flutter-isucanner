import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/api_response.dart';
import '../variables/ip_address.dart';
import 'package:http/http.dart' as http;

Future<ApiResponse> getDocument(String? token) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String userId = prefs.getInt('userId').toString();
  ApiResponse apiResponse = ApiResponse();

  try {

    final response = await http.get(
      Uri.parse('$ipaddress/task_document/${userId.toString()}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    switch(response.statusCode){
      case 200:
        apiResponse.data = jsonDecode(response.body)['tasks'];
        break;
      case 422:
        final errors = jsonDecode(response.body)['message'];
        apiResponse.error = errors;
        break;
      case 403:
        apiResponse.error = jsonDecode(response.body)['message'];
        break;
      default:
        apiResponse.error = 'Something went wrong.';
        final errors = jsonDecode(response.body)['message'];
        apiResponse.error = errors;
        break;
    }

  } catch(e){
    apiResponse.error = 'Something went wrong. $e';
  }

  return apiResponse;
}