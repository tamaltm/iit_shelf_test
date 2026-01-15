import 'dart:io';
import 'package:flutter/material.dart';

/// Small helper widget that renders either a network image or a local asset
/// depending on the provided [src]. It also normalizes file:// URIs and
/// provides an errorBuilder fallback.
class BookImage extends StatelessWidget {
  final String src;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const BookImage(this.src, {super.key, this.width, this.height, this.fit});

  bool get _isNetwork => src.startsWith('http');

  bool get _isFilePath {
    return src.startsWith('/') ||
        src.startsWith('file://') ||
        RegExp(r'^[a-zA-Z]:\\').hasMatch(src);
  }

  String _normalizeAssetPath(String s) {
    // If a file:// URI was supplied, convert to a relative asset path.
    if (s.startsWith('file://')) {
      try {
        final uri = Uri.parse(s);
        var p = uri.path;
        if (p.startsWith('/')) p = p.substring(1);
        return p;
      } catch (_) {
        return s.replaceFirst('file://', '');
      }
    }
    // Leave other paths untouched (e.g. 'lib/assets/...')
    return s;
  }

  @override
  Widget build(BuildContext context) {
    // If src is empty, show placeholder
    if (src.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.book, color: Colors.white54),
      );
    }

    if (_isNetwork) {
      return Image.network(
        src,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.book, color: Colors.white54),
          );
        },
      );
    }
    // If the source looks like a platform file path, load from file
    if (_isFilePath) {
      var p = src;
      if (p.startsWith('file://')) {
        try {
          p = Uri.parse(p).toFilePath();
        } catch (_) {
          p = p.replaceFirst('file://', '');
        }
      }
      final file = File(p);
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[800],
            child: const Icon(Icons.book, color: Colors.white54),
          );
        },
      );
    }

    final assetPath = _normalizeAssetPath(src);
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[800],
          child: const Icon(Icons.book, color: Colors.white54),
        );
      },
    );
  }
}
