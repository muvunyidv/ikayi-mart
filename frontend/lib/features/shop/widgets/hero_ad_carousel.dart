import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class HeroPromoSlide {
  const HeroPromoSlide({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.icon,
    this.background = const Color(0xFFFDF3E7),
    this.accent = AppColors.primaryOrange,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final IconData icon;
  final Color background;
  final Color accent;
}

/// Prominent storefront hero with auto-playing promo slides.
class HeroAdCarousel extends StatelessWidget {
  const HeroAdCarousel({
    super.key,
    this.productImageUrls = const [],
    this.onCta,
    this.slides = kDefaultHeroSlides,
  });

  final List<String> productImageUrls;
  final VoidCallback? onCta;
  final List<HeroPromoSlide> slides;

  static const kDefaultHeroSlides = <HeroPromoSlide>[
    HeroPromoSlide(
      title: 'Flash Deals Across Kigali!',
      subtitle:
          'Order now and get it in 60 minutes across Gasabo, Kicukiro & Nyarugenge.',
      ctaLabel: 'Explore Deals →',
      icon: Icons.bolt_rounded,
      background: Color(0xFFFDF3E7),
    ),
    HeroPromoSlide(
      title: 'Eco-friendly products that make an impact.',
      subtitle:
          'Sustainable solutions for your business—because the future of our planet matters too.',
      ctaLabel: 'Shop the range →',
      icon: Icons.eco_rounded,
      background: Color(0xFFFFE8DE),
    ),
    HeroPromoSlide(
      title: 'Free 60-min Kigali delivery.',
      subtitle:
          'On orders over 30,000 RWF — shop local vendors and get it the same hour.',
      ctaLabel: 'Shop Now →',
      icon: Icons.delivery_dining_rounded,
      background: Color(0xFFFFF6EE),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;
    return _HeroAdCarouselView(
      key: ValueKey(isDesktop),
      slides: slides,
      productImageUrls: productImageUrls,
      onCta: onCta,
      isDesktop: isDesktop,
    );
  }
}

class _HeroAdCarouselView extends StatefulWidget {
  const _HeroAdCarouselView({
    super.key,
    required this.slides,
    required this.productImageUrls,
    required this.onCta,
    required this.isDesktop,
  });

  final List<HeroPromoSlide> slides;
  final List<String> productImageUrls;
  final VoidCallback? onCta;
  final bool isDesktop;

  @override
  State<_HeroAdCarouselView> createState() => _HeroAdCarouselViewState();
}

class _HeroAdCarouselViewState extends State<_HeroAdCarouselView> {
  static const _autoPlayInterval = Duration(seconds: 5);
  static const _resumeDelay = Duration(seconds: 6);
  static const _animDuration = Duration(milliseconds: 600);

  late final PageController _controller;
  late final int _initialPage;
  Timer? _autoTimer;
  Timer? _resumeTimer;
  int _currentIndex = 0;
  bool _userInteracting = false;

  List<HeroPromoSlide> get _slides => widget.slides;

  @override
  void initState() {
    super.initState();
    _initialPage = _slides.length * 500;
    _controller = PageController(
      initialPage: _initialPage,
      viewportFraction: 1.0,
    );
    _controller.addListener(_syncIndex);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    _controller.removeListener(_syncIndex);
    _controller.dispose();
    super.dispose();
  }

  void _syncIndex() {
    if (!_controller.hasClients || _slides.isEmpty) return;
    final page = _controller.page;
    if (page == null) return;
    final index = page.round() % _slides.length;
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _startAutoPlay() {
    _autoTimer?.cancel();
    if (_slides.length < 2) return;
    _autoTimer = Timer.periodic(_autoPlayInterval, (_) {
      if (!mounted || _userInteracting || !_controller.hasClients) return;
      final next = (_controller.page?.round() ?? _initialPage) + 1;
      _controller.animateToPage(
        next,
        duration: _animDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseAutoPlay() {
    _userInteracting = true;
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
  }

  void _scheduleResume() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeDelay, () {
      if (!mounted) return;
      _userInteracting = false;
      _startAutoPlay();
    });
  }

  List<String> _imagesFor(int slideIndex) {
    final urls = widget.productImageUrls;
    if (urls.isEmpty) return const [];
    final a = urls[slideIndex % urls.length];
    if (urls.length == 1) return [a];
    final b = urls[(slideIndex + 1) % urls.length];
    return [a, b];
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.isDesktop ? 280.0 : 360.0;

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Listener(
                onPointerDown: (_) => _pauseAutoPlay(),
                onPointerUp: (_) => _scheduleResume(),
                onPointerCancel: (_) => _scheduleResume(),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollStartNotification && n.dragDetails != null) {
                      _pauseAutoPlay();
                    } else if (n is ScrollEndNotification) {
                      _scheduleResume();
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _controller,
                    padEnds: false,
                    clipBehavior: Clip.hardEdge,
                    itemBuilder: (context, index) {
                      final slideIndex = index % _slides.length;
                      final slide = _slides[slideIndex];
                      return _HeroSlideCard(
                        slide: slide,
                        imageUrls: _imagesFor(slideIndex),
                        onCta: widget.onCta,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_slides.length > 1) ...[
          const SizedBox(height: 4),
          _SlideDots(
            count: _slides.length,
            index: _currentIndex,
            onDotTap: (i) {
              if (!_controller.hasClients) return;
              _pauseAutoPlay();
              final page = _controller.page?.round() ?? _initialPage;
              final current = page % _slides.length;
              final delta = i - current;
              _controller.animateToPage(
                page + delta,
                duration: _animDuration,
                curve: Curves.easeInOut,
              );
              _scheduleResume();
            },
          ),
        ],
      ],
    );
  }
}

class _HeroSlideCard extends StatelessWidget {
  const _HeroSlideCard({
    required this.slide,
    required this.imageUrls,
    required this.onCta,
  });

  final HeroPromoSlide slide;
  final List<String> imageUrls;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 560;
        final padding = stacked ? 20.0 : 28.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                slide.background,
                Color.lerp(slide.background, slide.accent, 0.10)!,
              ],
            ),
          ),
          child: stacked
              ? Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _HeroCopy(
                          slide: slide,
                          onCta: onCta,
                          compact: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 2,
                        child: _HeroVisual(slide: slide, imageUrls: imageUrls),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          padding,
                          padding,
                          12,
                          padding,
                        ),
                        child: _HeroCopy(
                          slide: slide,
                          onCta: onCta,
                          compact: false,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: _HeroVisual(slide: slide, imageUrls: imageUrls),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.slide,
    required this.onCta,
    required this.compact,
  });

  final HeroPromoSlide slide;
  final VoidCallback? onCta;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = compact
        ? Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: AppColors.darkText,
          )
        : Theme.of(context).textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 32,
            height: 1.2,
            color: AppColors.darkText,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          slide.title,
          maxLines: compact ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          slide.subtitle,
          maxLines: compact ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.secondary,
            height: 1.45,
            fontSize: compact ? 13 : 15,
          ),
        ),
        SizedBox(height: compact ? 14 : 20),
        FilledButton(
          onPressed: onCta,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(slide.ctaLabel),
        ),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({required this.slide, required this.imageUrls});

  final HeroPromoSlide slide;
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final blob = size.shortestSide;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -blob * 0.18,
                bottom: -blob * 0.22,
                child: Container(
                  width: blob * 0.95,
                  height: blob * 0.95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: slide.accent.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                right: blob * 0.08,
                top: blob * 0.02,
                child: Container(
                  width: blob * 0.42,
                  height: blob * 0.42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: slide.accent.withValues(alpha: 0.10),
                  ),
                ),
              ),
              if (imageUrls.isNotEmpty)
                Positioned(
                  right: 20,
                  bottom: 12,
                  child: _ProductCutout(
                    url: imageUrls.first,
                    diameter: blob * 0.62,
                    accent: slide.accent,
                  ),
                ),
              if (imageUrls.length > 1)
                Positioned(
                  right: blob * 0.48,
                  top: 16,
                  child: _ProductCutout(
                    url: imageUrls[1],
                    diameter: blob * 0.34,
                    accent: slide.accent,
                  ),
                ),
              if (imageUrls.isEmpty)
                Positioned(
                  right: 28,
                  bottom: 20,
                  child: Container(
                    width: blob * 0.55,
                    height: blob * 0.55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.72),
                      boxShadow: [
                        BoxShadow(
                          color: slide.accent.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      slide.icon,
                      size: blob * 0.26,
                      color: slide.accent,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductCutout extends StatelessWidget {
  const _ProductCutout({
    required this.url,
    required this.diameter,
    required this.accent,
  });

  final String url;
  final double diameter;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final size = diameter.clamp(72.0, 220.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Icon(Icons.shopping_bag_outlined, color: accent, size: size * 0.4),
      ),
    );
  }
}

class _SlideDots extends StatelessWidget {
  const _SlideDots({
    required this.count,
    required this.index,
    required this.onDotTap,
  });

  final int count;
  final int index;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return GestureDetector(
          onTap: () => onDotTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: active ? 22 : 8,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primaryOrange
                  : AppColors.primaryOrange.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }),
    );
  }
}
