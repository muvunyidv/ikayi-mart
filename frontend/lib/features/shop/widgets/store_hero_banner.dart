import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Full-bleed store channel hero: product images cross-fade behind a
/// centered glassmorphism branding card.
class StoreHeroBanner extends StatelessWidget {
  const StoreHeroBanner({
    super.key,
    required this.storeName,
    this.description,
    this.phone,
    this.contactEmail,
    this.imageUrls = const [],
  });

  final String storeName;
  final String? description;
  final String? phone;
  final String? contactEmail;
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;
    return _StoreHeroBannerView(
      storeName: storeName,
      description: description,
      phone: phone,
      contactEmail: contactEmail,
      imageUrls: imageUrls,
      isDesktop: isDesktop,
    );
  }
}

class _StoreHeroBannerView extends StatefulWidget {
  const _StoreHeroBannerView({
    required this.storeName,
    required this.description,
    required this.phone,
    required this.contactEmail,
    required this.imageUrls,
    required this.isDesktop,
  });

  final String storeName;
  final String? description;
  final String? phone;
  final String? contactEmail;
  final List<String> imageUrls;
  final bool isDesktop;

  @override
  State<_StoreHeroBannerView> createState() => _StoreHeroBannerViewState();
}

class _StoreHeroBannerViewState extends State<_StoreHeroBannerView> {
  static const _interval = Duration(seconds: 4);
  static const _fade = Duration(milliseconds: 900);

  int _index = 0;
  Timer? _timer;

  List<String> get _urls => widget.imageUrls.where((u) => u.isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _StoreHeroBannerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.join('|') != widget.imageUrls.join('|')) {
      _index = 0;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_urls.length < 2) return;
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _urls.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.isDesktop ? 320.0 : 360.0;
    final urls = _urls;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF1A120E)),
            if (urls.isEmpty)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D1F12), Color(0xFF1A120E)],
                  ),
                ),
              )
            else
              for (var i = 0; i < urls.length; i++)
                AnimatedOpacity(
                  opacity: i == _index ? 1 : 0,
                  duration: _fade,
                  curve: Curves.easeInOut,
                  child: Image.network(
                    urls[i],
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFF2A1A14),
                    ),
                  ),
                ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000),
                    Color(0xB3000000),
                    Color(0xCC000000),
                  ],
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isDesktop ? 48 : 20,
                  vertical: 24,
                ),
                child: _StoreBrandCard(
                  storeName: widget.storeName,
                  description: widget.description,
                  phone: widget.phone,
                  contactEmail: widget.contactEmail,
                  compact: !widget.isDesktop,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreBrandCard extends StatelessWidget {
  const _StoreBrandCard({
    required this.storeName,
    required this.description,
    required this.phone,
    required this.contactEmail,
    required this.compact,
  });

  final String storeName;
  final String? description;
  final String? phone;
  final String? contactEmail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bio = description?.trim() ?? '';
    final email = contactEmail?.trim() ?? '';
    final tel = phone?.trim() ?? '';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 32,
                vertical: compact ? 20 : 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    storeName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 26 : 34,
                      height: 1.15,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (bio.isNotEmpty) ...[
                    SizedBox(height: compact ? 8 : 12),
                    Text(
                      bio,
                      textAlign: TextAlign.center,
                      maxLines: compact ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.45,
                        fontSize: compact ? 13 : 15,
                      ),
                    ),
                  ],
                  if (email.isNotEmpty || tel.isNotEmpty) ...[
                    SizedBox(height: compact ? 14 : 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (email.isNotEmpty)
                          _ContactPill(icon: Icons.mail_outline, label: email),
                        if (tel.isNotEmpty)
                          _ContactPill(icon: Icons.phone_outlined, label: tel),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactPill extends StatelessWidget {
  const _ContactPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryOrange),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
