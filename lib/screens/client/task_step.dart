import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/api_response.dart';
import '../../variables/ip_address.dart';


class TrackOrderScreen extends StatefulWidget {
  @override
  State<TrackOrderScreen> createState() => TrackOrderScreenState();
}

class TrackOrderScreenState extends State<TrackOrderScreen> {
  String token = '';
  List<OrderStatus> statusList = [];

  @override
  void initState() {
    super.initState();
    getToken().then((_) => fetchTasks());
  }

  Future<void> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
  }

  Future<ApiResponse> fetchTasks() async {
    ApiResponse apiResponse = ApiResponse();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String taskId = prefs.getString('taskId') ?? '';

    try {
      final response = await http.get(
        Uri.parse('$ipaddress/template_history/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('Requesting URL: $ipaddress/template_history/$taskId');
      switch (response.statusCode) {
        case 200:
          final data = json.decode(response.body);
          apiResponse.data = data.map<OrderStatus>((item) {
            return OrderStatus(
              officeName: item['Office_name'],
              officeTask: item['Office_task'],
              newAllotedTime: item['New_alloted_time'],
              Status: item['task_status'],

            );
          }).toList();
          print('Response body: ${response.body}');
          break;
        case 404:
          apiResponse.error = 'No task found.';
          print('Response body: ${response.body}');
          break;
        case 422:
        case 403:
          apiResponse.error = jsonDecode(response.body)['message'];
          print('Response body: ${response.body}');
          break;
        default:
          apiResponse.error = 'Something went wrong.';
          print('Response body: ${response.body}');
          break;
      }
    } catch (e) {
      apiResponse.error = 'Something went wrongs. $e';
      print( apiResponse.error);
    }

    return apiResponse;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Document'),
      ),
      body: FutureBuilder<ApiResponse>(
        future: fetchTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data?.error != null) {
            return Center(child: Text('Error: ${snapshot.data?.error}'));
          } else {
            statusList = snapshot.data!.data as List<OrderStatus>;
            return ListView.builder(
              itemCount: statusList.length,
              itemBuilder: (context, index) {
                final item = statusList[index];
                return OrderStatusWidget(item: item);
              },
            );
          }
        },
      ),
    );
  }
}

// OrderStatus model remains the same
class OrderStatus {
  final String officeName;
  final String officeTask;
  final String newAllotedTime;
  final String Status;


  OrderStatus({
    required this.officeName,
    required this.officeTask,
    required this.newAllotedTime,
    required this.Status,

  });
}

// The widget for displaying each order status remains the same
class OrderStatusWidget extends StatelessWidget {
  final OrderStatus item;

  const OrderStatusWidget({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32.0, top: 8.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${item.Status}'),
              Text('Office: ${item.officeName}'),
              Text('Task: ${item.officeTask}'),
              Text('Alloted Time: ${item.newAllotedTime}'),
            ],
          ),
        ),
        Divider(),
      ],
    );
  }
}