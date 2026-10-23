import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../utils/helpers/app_icon_service.dart';

/// 🎨 AppIconWidget — Displays authentic app icon for any Android package
///
/// Hierarchy:
/// 1. Direct bytes/url (if already provided)
/// 2. Native parent device PackageManager (instant)
/// 3. Google Play Store cached icon via CachedNetworkImage
/// 4. Branded fallback icon or stylish initial avatar
class AppIconWidget extends StatefulWidget {
  const AppIconWidget({
    super.key,
    required this.packageName,
    this.appName,
    this.category,
    this.size = 40,
    this.borderRadius,
    this.iconBytes,
    this.iconUrl,
  });

  final String packageName;
  final String? appName;
  final String? category;
  final double size;
  final double? borderRadius;
  final Uint8List? iconBytes;
  final String? iconUrl;

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  Uint8List? _nativeBytes;
  String? _playStoreUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nativeBytes = widget.iconBytes;
    _playStoreUrl = widget.iconUrl;
    _resolveIcon();
  }

  @override
  void didUpdateWidget(covariant AppIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName ||
        oldWidget.iconBytes != widget.iconBytes ||
        oldWidget.iconUrl != widget.iconUrl) {
      _nativeBytes = widget.iconBytes;
      _playStoreUrl = widget.iconUrl;
      _resolveIcon();
    }
  }

  Future<void> _resolveIcon() async {
    if (_nativeBytes != null || (_playStoreUrl != null && _playStoreUrl!.isNotEmpty)) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (widget.packageName.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 1. Try native channel first
    final native = await AppIconService.instance.getNativeIcon(widget.packageName);
    if (!mounted) return;
    if (native != null && native.isNotEmpty) {
      setState(() {
        _nativeBytes = native;
        _isLoading = false;
      });
      return;
    }

    // 2. Try Google Play Store / local cache
    final url = await AppIconService.instance.getIconUrl(widget.packageName);
    if (!mounted) return;
    setState(() {
      _playStoreUrl = url;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? (widget.size * 0.22);
    final brandColor = AppIconService.instance.getAppBrandColor(
      widget.packageName,
      appName: widget.appName,
    );

    // Case 1: Native or direct bytes
    if (_nativeBytes != null && _nativeBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.memory(
          _nativeBytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(brandColor, radius),
        ),
      );
    }

    // Case 2: Play Store or network URL
    if (_playStoreUrl != null && _playStoreUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: _playStoreUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          memCacheWidth: (widget.size * 2).toInt(),
          memCacheHeight: (widget.size * 2).toInt(),
          placeholder: (_, __) => _buildFallback(brandColor, radius),
          errorWidget: (_, __, ___) => _buildFallback(brandColor, radius),
        ),
      );
    }

    // Case 3: Fallback (or while loading)
    return _buildFallback(brandColor, radius);
  }

  Widget _buildFallback(Color brandColor, double radius) {
    final iconData = AppIconService.instance.getFallbackIcon(
      widget.packageName,
      category: widget.category,
    );

    final displayName = widget.appName?.trim() ?? '';
    final hasLetter = displayName.isNotEmpty &&
        RegExp(r'^[a-zA-Z0-9]').hasMatch(displayName);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: brandColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Center(
        child: hasLetter && iconData == Icons.apps
            ? Text(
                displayName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: widget.size * 0.45,
                  fontWeight: FontWeight.w800,
                  color: brandColor,
                ),
              )
            : Icon(
                iconData,
                color: brandColor,
                size: widget.size * 0.52,
              ),
      ),
    );
  }
}
