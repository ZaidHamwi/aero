import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

// Import custom widgets
import '../widgets/speedometer.dart';
import '../widgets/minimap.dart';
import '../widgets/media_player.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _currentSpeed = 0.0;
  StreamSubscription<Position>? _positionStream;

  bool _isInitialized = false; // stops UI from loading until permissions are handled

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _requestLocationPermission();
    
    await _requestNotiPermission();

    await _startTrackingSpeed(); 

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }

  Future<void> _requestNotiPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
    bool listenerStatus = await NotificationListenerService.isPermissionGranted();

    if (!listenerStatus) {
      _showPermissionDialog();
      // await NotificationListenerService.requestPermission();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 30, 30, 30),
        title: const Text("Notification Access Required \n\n PLEASE READ CAREFULLY", style: TextStyle(color: Colors.white)),
        content: const Text(
          "To display your music, Aero needs to be given the 'Notification read, reply and control' permission.\n\nPlease tap on 'Aero' and then tap 'Allow' on following settings screen. \n\n Aero will NEED to restart after that. \n\n You might not be allowed to grant the permission because android might first need you to manually do the following: \n\n - Open Settings\n - Go to Apps\n\n - Tap 'Aero'\n - Tap on the 3 dots in the top right corner\n - Tap 'Allow restricted access'\n - Enable the toggle for Aero\n\n Then you may comne back here to grant the permission.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await NotificationListenerService.requestPermission();
            },
            child: const Text("Go to Settings", style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _startTrackingSpeed() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation, 
      distanceFilter: 0, 
      intervalDuration: const Duration(milliseconds: 200), 
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      double speedKmh = position.speed * 3.6;
      if (speedKmh < 1.5) speedKmh = 0.0;
      setState(() {
        _currentSpeed = speedKmh;
      });
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            return PortraitView(speed: _currentSpeed); 
          } else {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            return LandscapeView(speed: _currentSpeed);
          }
        },
      ),
    );
  }
}

// --- PORTRAIT LAYOUT ---
class PortraitView extends StatelessWidget {
  final double speed;
  const PortraitView({super.key, required this.speed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 1), 
          Center(
            child: Speedometer(
              currentSpeed: speed, 
              maxSpeed: 60.0,
              unit: 'km/h',
            ),
          ),
          const Spacer(flex: 1),
          Center(
            child: MiniMap(),
          ),
          const Spacer(flex: 1),
          const Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: MediaPlayerWidget(
              width: 250,
              verticleButtons: true,
            ),
          ),
        ],
      ),
    );
  }
}

// --- LANDSCAPE LAYOUT ---
class LandscapeView extends StatelessWidget {
  final double speed;
  const LandscapeView({super.key, required this.speed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Row(
          children: [
            const Spacer(flex: 4),
            Speedometer(
              currentSpeed: speed, 
              maxSpeed: 60.0,
              unit: 'km/h',
            ),
            const Spacer(flex: 3),
            MiniMap(),
            const Spacer(flex: 2)
          ],
        ),
        const Spacer(),
        
        const Padding(
          padding: EdgeInsets.only(bottom: 5.0),
          child: MediaPlayerWidget(),
        ),
      ],
    );
  }
}