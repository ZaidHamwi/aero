import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';

class MediaPlayerWidget extends StatefulWidget {
  const MediaPlayerWidget({super.key});

  @override
  State<MediaPlayerWidget> createState() => _MediaPlayerWidgetState();
}

class _MediaPlayerWidgetState extends State<MediaPlayerWidget> {
  String title = 'No Media';
  String artist = 'Waiting for playback...';
  bool isPlaying = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPollingMedia();
  }

  void _startPollingMedia() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final mediaInfo = await FlutterMediaController.getCurrentMediaInfo();
        if (mounted) {
          setState(() {
            title = mediaInfo.track ?? 'No Media';
            artist = mediaInfo.artist ?? 'Waiting...';
            isPlaying = mediaInfo.isPlaying ?? false;
          });
        }
      } catch (e) { /* Ignore */ }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.music_note_rounded, size: 48, color: Colors.white24),
        const SizedBox(width: 20),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 350,
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 350,
              child: Text(
                artist,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70),
              onPressed: () => FlutterMediaController.previousTrack(),
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded),
              iconSize: 60,
              color: Colors.white,
              onPressed: () => FlutterMediaController.togglePlayPause(),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white70),
              onPressed: () => FlutterMediaController.nextTrack(),
            ),
          ],
        ),
      ],
    );
  }
}