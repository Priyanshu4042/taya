import 'package:flutter/material.dart';
import 'package:taya/auth_service.dart';

import '../calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
                onPressed: (){
                  AuthService().signOut();
                },
                child: const Text("Logout")
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await CalendarService().createTestCalendarEvent();

                  print('Calendar event created!');
                } catch (e) {
                  print('Failed to create calendar event: $e');
                }
              },
              child: const Text('Create Calendar Event'),
            ),
          ],
        )
      )
    );
  }
}
