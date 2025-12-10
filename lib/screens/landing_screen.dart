import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:divergent_alliance/ui/screens/home_screen.dart';
import 'package:divergent_alliance/screens/weather_center_pro.dart';
import 'package:divergent_alliance/ui/shop_under_construction.dart';

/// LandingScreen:
///  - Portrait  -> the original mobile HomeScreen (your app landing).
///  - Landscape -> looping hero video with animated neon "ELECTRIFY THE GRID"
///                 and Weather / Shop buttons.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingConfig {
  static const String heroVideoPath = 'assets/video/da_hero.mp4';
  static const String wallpaperPath = 'assets/images/wallpaper.png';
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _video;
  bool _videoReady = false;
  bool _showTapToPlay = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _video = VideoPlayerController.asset(_LandingConfig.heroVideoPath)
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoReady = true);

        // Try autoplay; if the platform blocks it (iOS Safari) we show tap overlay.
        _video.play().catchError((_) {
          if (mounted) {
            setState(() => _showTapToPlay = true);
          }
        });
      });

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _fade = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _anim,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _video.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isPortrait = size.height >= size.width;

    // PORTRAIT  -> your original mobile landing
    if (isPortrait) {
      return HomeScreen();
    }

    // LANDSCAPE -> hero video + neon HUD
    return _buildLandscape(context);
  }

  Widget _buildLandscape(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (_videoReady && !_video.value.isPlaying) {
            _video.play();
            setState(() => _showTapToPlay = false);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background hero video
            if (_videoReady && _video.value.isInitialized)
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

            // Dark / orange gradient overlay for intel HUD look
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xE6000000),
                    Color(0x99000000),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    const Spacer(),
                    FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: _buildNeonTitle(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Storm response, material supply, and live outage '
                      'intelligence for the crews that keep the grid alive.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 16,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildButtonsRow(context, compact: false),
                  ],
                ),
              ),
            ),

            if (_showTapToPlay)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.70),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.orangeAccent.withOpacity(0.9),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_circle_fill_rounded,
                          color: Colors.orangeAccent, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Tap to activate feed',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          letterSpacing: 1.3,
                          fontSize: 13,
                        ),
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

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orangeAccent.withOpacity(0.7),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Colors.orangeAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'DIVERGENT  ALLIANCE',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 3.0,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.orangeAccent.withOpacity(0.7),
            ),
            color: Colors.black.withOpacity(0.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.circle, size: 8, color: Colors.greenAccent),
              SizedBox(width: 8),
              Text(
                'WX PRO LIVE FEED',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeonTitle() {
    const baseColor = Color(0xFFFF8A00);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OPERATIONAL WEATHER INTELLIGENCE',
          style: TextStyle(
            color: Colors.white70,
            letterSpacing: 3.5,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Text(
              'ELECTRIFY THE GRID',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.6
                  ..color = Colors.deepOrange.shade900,
              ),
            ),
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFFFFF6E5),
                    baseColor,
                    Color(0xFFFF3D00),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
              child: const Text(
                'ELECTRIFY THE GRID',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: baseColor,
                      blurRadius: 22,
                    ),
                    Shadow(
                      color: baseColor,
                      blurRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButtonsRow(BuildContext context, {required bool compact}) {
    final double height = compact ? 48 : 52;
    final EdgeInsets padding =
        compact ? const EdgeInsets.symmetric(horizontal: 18) : const EdgeInsets.symmetric(horizontal: 24);

    return Row(
      children: [
        // WEATHER CENTER
        SizedBox(
          height: height,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              padding: padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => WeatherCenterPro()),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.cloud_queue_rounded, size: 22),
                SizedBox(width: 8),
                Text(
                  'WEATHER CENTER',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // SHOP
        SizedBox(
          height: height,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orangeAccent,
              side: const BorderSide(color: Colors.orangeAccent, width: 1.4),
              padding: padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ShopUnderConstruction()),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.storefront_outlined, size: 22),
                SizedBox(width: 8),
                Text(
                  'SHOP',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
