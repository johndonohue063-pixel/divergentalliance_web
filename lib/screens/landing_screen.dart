import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:divergent_alliance/ui/screens/weather_center_screen.dart';
import 'package:divergent_alliance/ui/screens/shop_screen.dart';

/// LandingScreen:
/// - Portrait (phones): wallpaper hero + app‑style buttons.
/// - Landscape / desktop: looping hero video + neon animated headline.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glow;

  late final VideoPlayerController _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _videoController = VideoPlayerController.asset('assets/video/da_hero.mp4')
      ..setLooping(true)
      ..setVolume(0);

    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() => _videoReady = true);
      // Try to autoplay – if the browser blocks it, we still have wallpaper fallback.
      _videoController.play();
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  bool _isPortrait(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.height >= size.width;
  }

  bool _isDesktopLike(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 800;
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = _isPortrait(context);
    final isDesktop = _isDesktopLike(context);

    if (isPortrait) {
      // Mobile: app‑like hero on top of wallpaper, no web chrome.
      return const _MobileLanding();
    }

    final showVideo = isDesktop && _videoReady;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background video or wallpaper fallback.
          Positioned.fill(
            child: showVideo
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Image.asset(
                    'assets/images/wallpaper.png',
                    fit: BoxFit.cover,
                  ),
          ),

          // Dark gradient overlay to get that intel HUD readability.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.92),
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.98),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Neon HUD content.
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 64, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDesktopTopBar(),
                  const Spacer(),
                  _buildNeonTitle(),
                  const SizedBox(height: 16),
                  Text(
                    'Storm response, material supply, and real-time outage intelligence '
                    'for the crews that keep the grid alive.',
                    style: TextStyle(
                      color: Colors.orange.shade100.withOpacity(0.9),
                      letterSpacing: 1.3,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildDesktopActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTopBar() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFFF8800).withOpacity(0.8),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.radar,
            color: Color(0xFFFF8800),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'D I V E R G E N T   A L L I A N C E',
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 3,
            color: Colors.orange.shade200,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.orangeAccent.withOpacity(0.5),
              width: 1,
            ),
            color: Colors.black.withOpacity(0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'WX PRO LIVE FEED',
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

  Widget _buildNeonTitle() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = 30.0 * _glow.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OPERATIONAL WEATHER INTELLIGENCE',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 4,
                color: Colors.orange.shade100.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                // Outline stroke
                Text(
                  'ELECTRIFY THE GRID',
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 1.6
                      ..color = Colors.orange.shade700,
                  ),
                ),
                // Neon fill + glow
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [
                        Colors.orange.shade50,
                        Colors.orange.shade400,
                        Colors.deepOrange.shade900,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Text(
                    'ELECTRIFY THE GRID',
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: Colors.orangeAccent
                              .withOpacity(0.8 * _glow.value),
                          blurRadius: glow,
                        ),
                        Shadow(
                          color: Colors.deepOrange
                              .withOpacity(0.7 * _glow.value),
                          blurRadius: glow / 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopActions(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent.withOpacity(0.15),
            foregroundColor: Colors.orangeAccent,
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: Colors.orangeAccent.withOpacity(0.9),
                width: 1.5,
              ),
            ),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const WeatherCenterScreen(),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud, size: 22),
              const SizedBox(width: 10),
              Text(
                'WEATHER CENTER',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade100,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: Colors.orange.shade200,
              width: 1.2,
            ),
            foregroundColor: Colors.orange.shade100,
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ShopScreen(),
              ),
            );
          },
          child: const Text(
            'SHOP',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Mobile portrait experience: wallpaper + app-like layout.
class _MobileLanding extends StatelessWidget {
  const _MobileLanding();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallpaper.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.96),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Divergent Alliance',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'OPERATIONAL WEATHER INTELLIGENCE',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      letterSpacing: 2.4,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ELECTRIFY\nTHE GRID',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      height: 1.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Storm-hardening, utility supply, and real-time outage intelligence '
                    'built for linemen, operations, and storm response teams.',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _MobileButtons(),
                  const SizedBox(height: 16),
                  Text(
                    'Optimized for desktops and tablets in landscape. '
                    'Mobile phones use the in-app Divergent wallpaper experience.',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileButtons extends StatelessWidget {
  const _MobileButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A1A),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WeatherCenterScreen(),
                ),
              );
            },
            child: const Text(
              'WEATHER CENTER',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white, width: 1.1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ShopScreen(),
                ),
              );
            },
            child: const Text(
              'SHOP',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
