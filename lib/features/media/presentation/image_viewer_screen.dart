import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/widgets/steady_page_physics.dart';

/// Built-in image viewer: swipe between sibling images, pinch to zoom.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
    this.onActions,
  });

  final List<String> images;
  final int initialIndex;

  /// When set, a "⋮" button pops the viewer and runs this callback
  /// (the file list uses it to show the current file's context menu).
  final VoidCallback? onActions;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageCtrl;
  late int _index;

  /// While the current image is zoomed in, horizontal swipes pan the
  /// picture instead of flipping pages.
  bool _zoomed = false;

  /// Two or more fingers down — pinch, never page.
  bool _pinch = false;

  /// Per-page transform controllers — zoom state is tracked per image.
  final Map<int, TransformationController> _ctrls = {};

  TransformationController _controllerFor(int i) {
    return _ctrls.putIfAbsent(i, () {
      final c = TransformationController();
      c.addListener(() {
        if (i != _index) return;
        final z = c.value.getMaxScaleOnAxis() > 1.001;
        if (z != _zoomed) setState(() => _zoomed = z);
      });
      return c;
    });
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.images[_index];
    final name = path.substring(path.lastIndexOf('/') + 1);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              '${_index + 1} / ${widget.images.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (widget.onActions != null)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onActions!();
              },
            ),
        ],
      ),
      body: PointerCounter(
        onChanged: (n) {
          final pinch = n > 1;
          if (pinch == _pinch) return;
          setState(() => _pinch = pinch);
          // A second finger landed mid-swipe → settle back on this page.
          if (pinch && _pageCtrl.hasClients) {
            _pageCtrl.animateToPage(
              _index,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
            );
          }
        },
        child: PageView.builder(
          controller: _pageCtrl,
          physics: _zoomed || _pinch
              ? const NeverScrollableScrollPhysics()
              : const SteadyPagePhysics(),
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() {
            _index = i;
            _zoomed = false;
          }),
          itemBuilder: (context, i) => InteractiveViewer(
            transformationController: _controllerFor(i),
            child: GestureDetector(
              // Long-press opens the same context menu as the "⋮" button.
              onLongPress: widget.onActions == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.onActions!();
                    },
              child: Center(
                child: Image.file(
                  File(widget.images[i]),
                  errorBuilder: (context, error, stack) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
