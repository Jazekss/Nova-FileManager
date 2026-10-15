import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';

/// Minimal plain-text editor. Opens text-like files (txt, md, html, js, php…),
/// edits in place and saves back to the same path.
class TextEditorScreen extends StatefulWidget {
  const TextEditorScreen({super.key, required this.path});

  final String path;

  /// Files larger than this are opened read-only is pointless — refuse.
  static const maxEditableBytes = 2 * 1024 * 1024;

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _dirty = false;
  String? _error;

  String get _name => widget.path.substring(widget.path.lastIndexOf('/') + 1);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = File(widget.path);
      final len = await file.length();
      if (len > TextEditorScreen.maxEditableBytes) {
        setState(() {
          _error = l10n(context).fileTooLarge;
          _loading = false;
        });
        return;
      }
      final text = await file.readAsString();
      if (!mounted) return;
      setState(() {
        _controller.text = text;
        _loading = false;
      });
      _controller.addListener(() {
        if (!_dirty) setState(() => _dirty = true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    try {
      await File(widget.path).writeAsString(_controller.text);
      if (!mounted) return;
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n(context).saved)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$_name${_dirty ? ' •' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: l10n(context).save,
            icon: const Icon(Icons.save_outlined),
            onPressed: _loading || _error != null ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spacingLg),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(AppTokens.spacingSm),
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                minLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
    );
  }
}
