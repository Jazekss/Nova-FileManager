import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';

/// Minimal video player: tap for controls, horizontal swipe to seek,
/// fullscreen toggle.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.path});

  final String path;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  String? _error;
  bool _controlsVisible = true;
  bool _fullscreen = false;
  Timer? _hideTimer;

  // Swipe-seek state
  Duration? _seekPreview;
  Duration _dragOrigin = Duration.zero;

  String get _name => widget.path.substring(widget.path.lastIndexOf('/') + 1);

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path));
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.play();
      if (mounted) setState(() => _ready = true);
      _scheduleHide();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    _exitFullscreen();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  Future<void> _toggleFullscreen() async {
    _fullscreen = !_fullscreen;
    if (_fullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await _exitFullscreen();
    }
    if (mounted) setState(() {});
  }

  Future<void> _exitFullscreen() async {
    _fullscreen = false;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  void _onDragStart(DragStartDetails d) {
    _dragOrigin = _controller.value.position;
    setState(() => _seekPreview = _dragOrigin);
  }

  void _onDragUpdate(DragUpdateDetails d, double width) {
    // Full horizontal swipe across the screen seeks ±90 seconds.
    final delta = d.primaryDelta ?? 0;
    final seconds = delta / width * 90;
    final target =
        (_seekPreview ?? _dragOrigin) +
        Duration(milliseconds: (seconds * 1000).round());
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(
        0,
        _controller.value.duration.inMilliseconds,
      ),
    );
    setState(() => _seekPreview = clamped);
  }

  Future<void> _onDragEnd(DragEndDetails d) async {
    final target = _seekPreview;
    setState(() => _seekPreview = null);
    if (target != null) await _controller.seekTo(target);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;
    final shown = _seekPreview ?? value.position;
    final duration = value.duration;

    final body = _error != null
        ? Center(child: Text(l10n(context).cannotPlay('$_error')))
        : !_ready
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTap: _toggleControls,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: (d) =>
                  _onDragUpdate(d, constraints.maxWidth),
              onHorizontalDragEnd: _onDragEnd,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  if (_seekPreview != null)
                    Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.all(AppTokens.spacingMd),
                      child: Text(
                        _fmt(_seekPreview!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      ),
                    ),
                  if (_controlsVisible) ...[
                    IconButton(
                      iconSize: 64,
                      color: Colors.white70,
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_circle
                            : Icons.play_circle,
                      ),
                      onPressed: () {
                        value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                        _scheduleHide();
                      },
                    ),
                    // Top overlay: back arrow + file name.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Container(
                          color: Colors.black45,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.spacingXs,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                color: Colors.white,
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                              Expanded(
                                child: Text(
                                  _name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Bottom controls — SafeArea keeps them above the
                    // system navigation bar.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        child: Container(
                          color: Colors.black45,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.spacingSm,
                          ),
                          child: Row(
                            children: [
                              Text(
                                _fmt(shown),
                                style: const TextStyle(color: Colors.white),
                              ),
                              Expanded(
                                child: Slider(
                                  value: shown.inMilliseconds
                                      .clamp(0, duration.inMilliseconds)
                                      .toDouble(),
                                  max: duration.inMilliseconds.toDouble().clamp(
                                    1,
                                    double.infinity,
                                  ),
                                  onChanged: (v) => _controller.seekTo(
                                    Duration(milliseconds: v.round()),
                                  ),
                                ),
                              ),
                              Text(
                                _fmt(duration),
                                style: const TextStyle(color: Colors.white),
                              ),
                              IconButton(
                                color: Colors.white,
                                icon: Icon(
                                  _fullscreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                ),
                                onPressed: _toggleFullscreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );

    // Same overlay layout in both modes — back/name on top, controls
    // above the navigation bar, everything auto-hides after 3 s.
    return Scaffold(body: body, backgroundColor: Colors.black);
  }
}
