import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/appointment_screen.dart';
import 'package:healthpost_app/chat_list_screen.dart';
import 'package:healthpost_app/home_page.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
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
    const DoctorAppointmentsScreen(),
    const DoctorChatListScreen(),
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.date_range),
            label: AppLocalizations.of(context)!.appointment,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: AppLocalizations.of(context)!.chat,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
      ),
    );
  }
}
