import 'package:flutter/material.dart';
import 'task_list_widget.dart'; 

class ClientCustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Text(
              'Drawer Header',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.menu_open_sharp),
            title: const Text('ACTIONS'),
            onTap: () {
              // Handle the tap here
            },
          ),
          // Template section with dropdown
          const ExpansionTile(
            leading: Icon(Icons.content_copy),
            title: Text('TEMPLATE'),
            children: <Widget>[
              TaskListWidget(),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.fact_check),
            title: const Text('TRACK DOCUMENT'),
            onTap: () {
              // Handle the tap here
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('TRANSACTION HISTORY'),
            onTap: () {
              // Handle the tap here
            },
          ),
          // Add more ListTiles for other drawer options
        ],
      ),
    );
  }
}
