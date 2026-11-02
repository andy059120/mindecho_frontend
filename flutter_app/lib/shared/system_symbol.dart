import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS 使用原 App 的 SF Symbols 字形；其他平台保留 Flutter fallback。
class SystemSymbol extends StatefulWidget {
  const SystemSymbol(
    this.name, {
    this.size = 20,
    this.weight = 'regular',
    this.color,
    this.fallback = CupertinoIcons.circle,
    super.key,
  });
  final String name;
  final double size;
  final String weight;
  final Color? color;
  final IconData fallback;
  static const _channel = MethodChannel('mindecho/system_symbols');
  static final _cache = <String, Future<Map<Object?, Object?>?>>{};

  @override
  State<SystemSymbol> createState() => _SystemSymbolState();
}

class _SystemSymbolState extends State<SystemSymbol> {
  Future<Map<Object?, Object?>?>? _image;
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(SystemSymbol oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name ||
        oldWidget.size != widget.size ||
        oldWidget.weight != widget.weight) {
      _resolve();
    }
  }

  void _resolve() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    final key = '${widget.name}:${widget.size}:${widget.weight}';
    _image = SystemSymbol._cache.putIfAbsent(key, () async {
      try {
        return await SystemSymbol._channel.invokeMapMethod<Object?, Object?>(
          'render',
          {'name': widget.name, 'size': widget.size, 'weight': widget.weight},
        );
      } on MissingPluginException {
        return null;
      } on PlatformException {
        return null;
      }
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _image,
    builder: (context, snapshot) {
      final image = snapshot.data;
      if (image == null) {
        return Icon(widget.fallback, size: widget.size, color: widget.color);
      }
      return Image.memory(
        image['bytes'] as Uint8List,
        width: (image['width'] as num).toDouble(),
        height: (image['height'] as num).toDouble(),
        color: widget.color ?? CupertinoTheme.of(context).primaryColor,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      );
    },
  );
}
