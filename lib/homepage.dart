import 'package:flutter/material.dart';
import 'package:taya/screens/calendar.dart';
import 'package:taya/screens/input.dart';
import 'package:taya/screens/items_screen.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // Default to Items

  late final List<Widget> _pages = [
    ItemsScreen(userId: widget.userId),
    MessageInputScreen(userId: widget.userId,),
    CalendarScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: "Items",
          ),
          NavigationDestination(
            icon: Icon(Icons.sms_outlined),
            selectedIcon: Icon(Icons.sms),
            label: "SMS",
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: "Calendar",
          ),
        ],
      ),
    );
  }
}