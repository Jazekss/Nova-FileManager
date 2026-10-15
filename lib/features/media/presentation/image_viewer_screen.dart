import 'dart:io';

import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
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
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
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
    );
  }
}
