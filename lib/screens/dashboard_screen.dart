import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';


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

  @override
  void initState() {
    super.initState();
    _startTrackingSpeed();
    _requestMediaPermission(); 
  }

  Future<void> _requestMediaPermission() async {
    try {
      await FlutterMediaController.requestPermissions();
    } catch (e) {
      // Ignore
    }
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
      intervalDuration: const Duration(milliseconds: 500), 
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
          const Spacer(flex: 2), 
          Center(
            child: Speedometer(
              currentSpeed: speed, 
              maxSpeed: 60.0,
              unit: 'km/h',
            ),
          ),
          const Spacer(flex: 3),
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