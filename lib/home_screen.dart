import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/appointment_screen.dart';
import 'package:healthpost_app/chat_screen.dart';
import 'package:healthpost_app/home_page.dart';
import 'package:healthpost_app/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controller/internet_status_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  final ConnectivityController controller = Get.put(
    ConnectivityController(),
    permanent: true,
  );

  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DoctorHomeScreen(),
    const AppointmentScreen(),
    const ChatScreen(),
    const DoctorProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.date_range),
            label: 'Appointment',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
