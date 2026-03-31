import 'dart:ui';
import 'package:flutter/material.dart';
import 'hospital_home.dart';
import 'hospital_cases.dart';
import '../../widgets/app_drawer.dart';

class HospitalDashboard extends StatefulWidget {
  const HospitalDashboard({super.key});

  @override
  State<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HospitalHomeContent(),
    const HospitalCasesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          "GeoTour",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -1.0,
          ),
        ),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: RepaintBoundary(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: navItem("Home", 0)),
                    Expanded(child: navItem("Cases", 1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget navItem(String label, int index) {
    bool selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutQuart,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? Colors.black.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
