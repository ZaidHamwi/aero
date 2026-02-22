import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MiniMap extends StatefulWidget {
  const MiniMap({Key? key}) : super(key: key);

  @override
  State<MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<MiniMap> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  LatLng? _currentLocation;

  // animation variables
  late AnimationController _animationController;
  LatLng? _startLocation;
  LatLng? _targetLocation;
  double _startRotation = 0;
  double _targetRotation = 0;

  // track current interpolated state
  LatLng _animatedLocation = const LatLng(0, 0);
  double _animatedRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_onAnimationUpdate);
    _initLocation();
  }

  void _onAnimationUpdate() {
    if (_startLocation == null || _targetLocation == null) return;

    final t = Curves.easeOutCubic.transform(_animationController.value);

    final lat = ui.lerpDouble(_startLocation!.latitude, _targetLocation!.latitude, t)!;
    final lng = ui.lerpDouble(_startLocation!.longitude, _targetLocation!.longitude, t)!;
    final rot = ui.lerpDouble(_startRotation, _targetRotation, t)!;

    _animatedLocation = LatLng(lat, lng);
    _animatedRotation = rot;

    _mapController.move(_animatedLocation, 17);
    _mapController.rotate(_animatedRotation);
  }

  // prevent map from spinning the wrong way around when crossing 0/360 deg
  double _getShortestRotation(double current, double target) {
    double diff = (target - current) % 360.0;
    if (diff < 0.0) diff += 360.0;
    if (diff > 180.0) diff -= 360.0;
    return current + diff;
  }

  Future<void> _initLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen((Position position) {
      final newLatLng = LatLng(position.latitude, position.longitude);
      final newTargetRot = position.heading != 0 ? (360 - position.heading) : 0.0;

      if (_currentLocation == null) {
        setState(() {
          _currentLocation = newLatLng;
        });
        _animatedLocation = newLatLng;
        _animatedRotation = newTargetRot;
      
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(newLatLng, 17);
          _mapController.rotate(newTargetRot);
        });
      } else {
        _startLocation = _animatedLocation;
        _startRotation = _animatedRotation;

        _targetLocation = newLatLng;
        _targetRotation = _getShortestRotation(_startRotation, newTargetRot);

        _animationController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 270,
        width: 350,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_currentLocation != null)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation!,
                  initialZoom: 17,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.app.bikespeedometer',
                  ),
                ],
              )
            else
              Container(
                color: const ui.Color(0xFF222222),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            CustomPaint(
              size: const Size(20, 20),
              painter: TrianglePainter(),
            ),
          ],
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width / 2, size.height / 1.3)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawShadow(path, Colors.black.withOpacity(0.4), 3, true);
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, fillPaint);
    final edgePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(path, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}