import 'package:flutter/material.dart';

// dashboard screen
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AeroApp());
}

// --- APP ---
class AeroApp extends StatelessWidget {
  const AeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aero',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          surface: Color.fromARGB(255, 0, 0, 0), 
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}