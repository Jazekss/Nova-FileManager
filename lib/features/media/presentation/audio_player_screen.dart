import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';

/// Minimal built-in audio player: play/pause and seek.
class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key, required this.path});

  final String path;

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final _player = AudioPlayer();
  final _subscriptions = <StreamSubscription<dynamic>>[];

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _ready = false;
  String? _error;

  String get _name => widget.path.substring(widget.path.lastIndexOf('/') + 1);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _subscriptions.addAll([
        _player.onDurationChanged.listen(
          (d) => mounted ? setState(() => _duration = d) : null,
        ),
        _player.onPositionChanged.listen(
          (p) => mounted ? setState(() => _position = p) : null,
        ),
        _player.onPlayerStateChanged.listen(
          (s) => mounted
              ? setState(() => _playing = s == PlayerState.playing)
              : null,
        ),
      ]);
      await _player.setSource(DeviceFileSource(widget.path));
      await _player.resume();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _error != null
          ? Center(child: Text(l10n(context).cannotPlay('$_error')))
          : Padding(
              padding: const EdgeInsets.all(AppTokens.spacingLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_note, size: 96),
                  const SizedBox(height: AppTokens.spacingLg),
                  if (!_ready)
                    const CircularProgressIndicator()
                  else ...[
                    Slider(
                      value: _position.inMilliseconds
                          .clamp(0, _duration.inMilliseconds)
                          .toDouble(),
                      max: _duration.inMilliseconds.toDouble().clamp(
                        1,
                        double.infinity,
                      ),
                      onChanged: (v) =>
                          _player.seek(Duration(milliseconds: v.round())),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text(_fmt(_position)), Text(_fmt(_duration))],
                    ),
                    const SizedBox(height: AppTokens.spacingMd),
                    IconButton.filled(
                      iconSize: 48,
                      icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                      onPressed: () =>
                          _playing ? _player.pause() : _player.resume(),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
