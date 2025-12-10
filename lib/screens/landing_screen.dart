import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:divergent_alliance/ui/screens/home_screen.dart';
import 'package:divergent_alliance/ui/screens/weather_center_screen.dart';
import 'package:divergent_alliance/ui/screens/shop_screen.dart';

/// LandingScreen:
/// - Portrait: your existing HomeScreen (wallpaper + your custom buttons).
/// - Landscape / Desktop: hero video + neon, animated military intel HUD.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glow;

  late final AnimationController _timeline; // drives ticker & scanline

  late final VideoPlayerController _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();

    // Neon glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glow = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    // Timeline for HUD animations
    _timeline = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Hero video (we assume assets/video/da_hero.mp4 exists â€“ no renames)
    _videoController =
        VideoPlayerController.asset('assets/video/da_hero.mp4')
          ..setLooping(true)
          ..setVolume(0);

    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() => _videoReady = true);
      _videoController.play();
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _timeline.dispose();
    _videoController.dispose();
    super.dispose();
  }

  bool _isPortrait(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.height >= size.width;
  }

  bool _isDesktopLike(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 900;
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = _isPortrait(context);
    final isDesktop = _isDesktopLike(context);

    // âœ… PORTRAIT: exactly your app home (wallpaper + your existing buttons)
    if (isPortrait) {
      return HomeScreen();
    }

    // âœ… LANDSCAPE / DESKTOP: hero video + animated HUD
    final showVideo = isDesktop && _videoReady;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background: hero video or wallpaper fallback
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
          // Dark intel overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.95),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.98),
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
                  const EdgeInsets.symmetric(horizontal: 64, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDesktopTopBar(),
                  const Spacer(),
                  _AnimatedHud(
                    glow: _glow,
                    timeline: _timeline,
                    onWeatherCenter: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WeatherCenterScreen(),
                        ),
                      );
                    },
                    onShop: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ShopScreen(),
                        ),
                      );
                    },
                  ),
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
          'DIVERGENT ALLIANCE',
          style: TextStyle(
            fontSize: 16,
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
            color: Colors.black.withOpacity(0.55),
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
}

/// Animated HUD: neon title that digitizes in, ticker scroll, scanline sweep.
class _AnimatedHud extends StatelessWidget {
  const _AnimatedHud({
    required this.glow,
    required this.timeline,
    required this.onWeatherCenter,
    required this.onShop,
  });

  final Animation<double> glow;
  final AnimationController timeline;
  final VoidCallback onWeatherCenter;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([glow, timeline]),
      builder: (context, _) {
        final t = timeline.value; // 0.0 - 1.0 over 8 seconds
        final titlePhase = (t * 3).clamp(0.0, 1.0);
        final subtitlePhase = ((t - 0.2) * 3).clamp(0.0, 1.0);
        final tickerPhase = (t * 2) % 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNeonTitle(glow.value, titlePhase),
            const SizedBox(height: 12),
            Opacity(
              opacity: subtitlePhase,
              child: _buildTagline(),
            ),
            const SizedBox(height: 24),
            _buildDesktopActions(context),
            const SizedBox(height: 24),
            _buildTicker(tickerPhase),
            const SizedBox(height: 8),
            _buildScanline(t),
          ],
        );
      },
    );
  }

  Widget _buildNeonTitle(double glowFactor, double phase) {
    final glowRadius = 25.0 + 20.0 * glowFactor;

    // Digitize: reveal text horizontally based on phase
    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: phase <= 0 ? 0.0 : phase.clamp(0.0, 1.0),
        child: Stack(
          children: [
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
                          .withOpacity(0.8 * glowFactor),
                      blurRadius: glowRadius,
                    ),
                    Shadow(
                      color:
                          Colors.deepOrange.withOpacity(0.7 * glowFactor),
                      blurRadius: glowRadius / 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Text(
      'Storm response, material supply, and live outage intelligence for the crews that keep the grid alive.',
      style: TextStyle(
        color: Colors.orange.shade100.withOpacity(0.9),
        letterSpacing: 1.3,
        fontSize: 14,
        height: 1.4,
      ),
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
          onPressed: onWeatherCenter,
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
          onPressed: onShop,
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

  Widget _buildTicker(double phase) {
    const text =
        ' VETERAN-OWNED â€¢ IBEW-BUILT â€¢ STORM CREWS 24/7 â€¢ LIVE OUTAGE INTEL â€¢ UTILITY R&D â€¢ GRID HARDENING ';

    return ClipRect(
      child: SizedBox(
        height: 22,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),
            FractionalTranslation(
              translation: Offset(-phase * 2, 0),
              child: Text(
                text + text,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.8,
                  color: Colors.orange.shade200,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanline(double t) {
    final y = (t * 2.0) % 2.0;

    return Align(
      alignment: Alignment(0, y - 1), // -1 to 1
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.orange.withOpacity(0.18),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}
