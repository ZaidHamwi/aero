import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';

// dashboard screen
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if notification permission is already granted
  final notificationStatus = await Permission.notification.status;
  if (!notificationStatus.isGranted) {
    // Only request if not already granted
    await Permission.notification.request();
  }
  
  // Try to access media info - if it fails, request notification listener service access
  try {
    await FlutterMediaController.getCurrentMediaInfo();
  } catch (e) {
    // Failed to access media - request notification listener service permission
    try {
      await FlutterMediaController.requestPermissions();
    } catch (e) {
      // Ignore if request fails
    }
  }
  
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