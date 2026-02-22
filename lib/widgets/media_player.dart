import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';

class MediaPlayerWidget extends StatefulWidget {
  final double width;
  final bool verticleButtons;

  const MediaPlayerWidget({
    super.key,
    this.width = 350,
    this.verticleButtons = false,
  });

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
      } catch (e) { 
        // STOP THE TIMER ON FAILURE!
        timer.cancel(); 
        if (mounted) {
          setState(() {
            title = 'Permission Needed';
            artist = 'Please restart app after granting';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  Widget _buildControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.verticleButtons) {
      // Vertical layout for portrait mode
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_note_rounded, size: 48, color: Colors.white24),
              const SizedBox(width: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: widget.width,
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: widget.width,
                    child: Text(
                      artist,
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildControls(),
        ],
      );
    } else {
      // Horizontal layout for landscape mode
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_note_rounded, size: 48, color: Colors.white24),
          const SizedBox(width: 20),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: widget.width,
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: widget.width,
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
          _buildControls(),
        ],
      );
    }
  }
}