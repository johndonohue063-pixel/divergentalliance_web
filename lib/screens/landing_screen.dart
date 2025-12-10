import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:divergent_alliance/screens/weather_center_pro.dart';
import 'package:divergent_alliance/ui/shop_under_construction.dart';

/// LandingScreen behavior:
/// - PORTRAIT (phones)  : wallpaper.png with two big buttons (Weather Center, Shop).
/// - LANDSCAPE (web/desktop/rotated devices):
///     full-screen looping hero video + animated neon intel HUD.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  static const _videoAsset = 'assets/video/da_hero.mp4';
  static const _wallpaper = 'assets/images/wallpaper.png';

  late final VideoPlayerController _video;
  bool _videoReady = false;

  late final AnimationController _hudController;
  late final Animation<double> _titleGlow;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    // HUD animation controller
    _hudController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _titleGlow = CurvedAnimation(
      parent: _hudController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(-0.12, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _hudController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuad),
      ),
    );

    _subtitleFade = CurvedAnimation(
      parent: _hudController,
      curve: const Interval(0.35, 0.9, curve: Curves.easeIn),
    );

    _buttonSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _hudController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Video background controller for landscape
    _video = VideoPlayerController.asset(_videoAsset)
      ..setLooping(true)
      ..setVolume(0.0); // keep muted for web / iOS autoplay

    _video.initialize().then((_) {
      if (!mounted) return;
      setState(() => _videoReady = true);

      // Try to autoplay (mobile Safari may still require tap)
      _video.play();
    });
  }

  @override
  void dispose() {
    _hudController.dispose();
    _video.dispose();
    super.dispose();
  }

  bool _isPortrait(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.height >= size.width;
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = _isPortrait(context);

    if (isPortrait) {
      // PURE MOBILE LANDING:
      // wallpaper + two large custom buttons only.
      return _buildPortraitLanding(context);
    }

    // LANDSCAPE: hero video + animated HUD
    return _buildLandscapeHero(context);
  }

  // --------------------------------------------------------------------------
  // PORTRAIT: Wallpaper + two big buttons (Weather Center, Shop)
  // --------------------------------------------------------------------------
  Widget _buildPortraitLanding(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Static wallpaper
          Image.asset(
            _wallpaper,
            fit: BoxFit.cover,
          ),
          // Gradient scrim at bottom for button readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          // Buttons anchored near bottom
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBigPrimaryButton(
                      context: context,
                      label: 'WEATHER CENTER',
                      icon: Icons.cloud,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WeatherCenterPro(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildBigOutlineButton(
                      context: context,
                      label: 'SHOP',
                      icon: Icons.storefront,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ShopUnderConstructionScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigPrimaryButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7A1A),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A1A).withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigOutlineButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFFF7A1A),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFF7A1A), size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF7A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // LANDSCAPE: Hero video + neon intel HUD
  // --------------------------------------------------------------------------
  Widget _buildLandscapeHero(BuildContext context) {
    if (_videoReady && !_video.value.isPlaying) {
      _video.play();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background video
          if (_videoReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _video.value.size.width,
                height: _video.value.size.height,
                child: VideoPlayer(_video),
              ),
            )
          else
            Container(color: Colors.black),

          // Subtle dark layer for intel HUD readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // HUD
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHudTopBar(context),
                  const Spacer(),
                  _buildHudTitleBlock(context),
                  const SizedBox(height: 24),
                  _buildHudSubtitle(),
                  const SizedBox(height: 32),
                  _buildHudButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudTopBar(BuildContext context) {
    return Row(
      children: [
        // small orange square logo
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF8A1F),
                Color(0xFFFFB347),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A1F).withOpacity(0.55),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.bolt_outlined,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        AnimatedBuilder(
          animation: _hudController,
          builder: (context, _) {
            final t = _hudController.value;
            final opacity = t < 0.2
                ? 0.0
                : t < 0.28
                    ? 1.0
                    : t < 0.35
                        ? 0.3
                        : 1.0; // little flicker
            return Opacity(
              opacity: opacity,
              child: Text(
                'DIVERGENT ALLIANCE',
                style: TextStyle(
                  fontSize: 16,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade100,
                ),
              ),
            );
          },
        ),
        const Spacer(),
        // Status pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.black.withOpacity(0.6),
            border: Border.all(
              color: Colors.orangeAccent.withOpacity(0.8),
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DIVERGENT ALLIANCE SYSTEMS LIVE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.8,
                  color: Colors.orange.shade100,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHudTitleBlock(BuildContext context) {
    return AnimatedBuilder(
      animation: _hudController,
      builder: (context, _) {
        final glow = 28.0 * _titleGlow.value;
        return SlideTransition(
          position: _titleSlide,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OPERATIONAL WEATHER INTELLIGENCE',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 3.0,
                  color: Colors.orange.shade100.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Text(
                    'ELECTRIFY THE GRID',
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1.4
                        ..color = Colors.orange.shade700,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFFFFF7D6),
                          Color(0xFFFFB347),
                          Color(0xFFFF6A00),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcATop,
                    child: Text(
                      'ELECTRIFY THE GRID',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFA040)
                                .withOpacity(0.9 * _titleGlow.value),
                            blurRadius: glow,
                          ),
                          Shadow(
                            color: Colors.deepOrange
                                .withOpacity(0.7 * _titleGlow.value),
                            blurRadius: glow / 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHudSubtitle() {
    return FadeTransition(
      opacity: _subtitleFade,
      child: const Text(
        'STORM SERVICES  â€¢  MATERIAL SUPPLY  â€¢  UTILITY R&D',
        style: TextStyle(
          fontSize: 15,
          letterSpacing: 2.2,
          color: Color(0xFFFFE6C7),
        ),
      ),
    );
  }

  Widget _buildHudButtons(BuildContext context) {
    return SlideTransition(
      position: _buttonSlide,
      child: Row(
        children: [
          _buildHudPrimaryButton(
            context: context,
            label: 'WEATHER CENTER',
            icon: Icons.cloud,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WeatherCenterPro(),
                ),
              );
            },
          ),
          const SizedBox(width: 18),
          _buildHudOutlineButton(
            context: context,
            label: 'SHOP',
            icon: Icons.storefront,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ShopUnderConstructionScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHudPrimaryButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF7A1A),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        shadowColor: const Color(0xFFFF7A1A).withOpacity(0.8),
        elevation: 18,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          const Text(
            'WEATHER CENTER',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudOutlineButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFFA040),
        side: const BorderSide(color: Color(0xFFFFA040), width: 1.6),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
