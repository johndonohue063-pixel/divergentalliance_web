import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:divergent_alliance/screens/weather_center_pro.dart';
import 'package:divergent_alliance/ui/shop_under_construction.dart';

/// LandingScreen
///  - Portrait: wallpaper + 2 big buttons (Weather Center, Shop).
///  - Landscape: hero video background + neon intel HUD + same buttons.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingAssets {
  static const String heroVideo = 'assets/video/da_hero.mp4';
  static const String wallpaper = 'assets/images/wallpaper.png';
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _video;
  bool _videoReady = false;
  bool _tapToPlayVisible = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    // Video controller (landscape only, but we initialise here)
    _video = VideoPlayerController.asset(_LandingAssets.heroVideo)
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoReady = true);

        _video.play().catchError((_) {
          if (!mounted) return;
          setState(() => _tapToPlayVisible = true);
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
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    if (isPortrait) {
      return _buildPortrait(context);
    } else {
      return _buildLandscape(context);
    }
  }

  // ---------------------------------------------------------------------------
  // PORTRAIT  -> wallpaper + 2 big buttons (Weather Center, Shop)
  // ---------------------------------------------------------------------------
  Widget _buildPortrait(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Wallpaper
          Image.asset(
            _LandingAssets.wallpaper,
            fit: BoxFit.cover,
          ),

          // Subtle dark gradient at bottom for buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Divergent Alliance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Operational Weather Intelligence',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Spacer(),
                  _buildMobileButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A00),
              foregroundColor: Colors.black,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cloud_queue_rounded, size: 22),
                SizedBox(width: 10),
                Text(
                  'WEATHER CENTER',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF8A00),
              side: const BorderSide(
                color: Color(0xFFFF8A00),
                width: 1.6,
              ),
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
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.storefront_outlined, size: 22),
                SizedBox(width: 10),
                Text(
                  'SHOP',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LANDSCAPE  -> hero video + neon intel HUD
  // ---------------------------------------------------------------------------
  Widget _buildLandscape(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (_videoReady && !_video.value.isPlaying) {
            _video.play();
            setState(() => _tapToPlayVisible = false);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
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

            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xE6000000),
                    Color(0x80000000),
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
                        color: Colors.white.withOpacity(0.86),
                        fontSize: 16,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildDesktopButtons(context),
                  ],
                ),
              ),
            ),

            if (_tapToPlayVisible)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.orangeAccent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_circle_fill_rounded,
                          color: Colors.orangeAccent),
                      SizedBox(width: 10),
                      Text(
                        'Tap to activate intel feed',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          letterSpacing: 1.3,
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.orangeAccent.withOpacity(0.8),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Colors.orangeAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        const Text(
          'DIVERGENT  ALLIANCE',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 3,
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
              color: Colors.orangeAccent.withOpacity(0.8),
            ),
            color: Colors.black.withOpacity(0.7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.circle, size: 8, color: Colors.greenAccent),
              SizedBox(width: 8),
              Text(
                'WX GRID READY',
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
            fontSize: 11,
            letterSpacing: 3.5,
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
                      blurRadius: 20,
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

  Widget _buildDesktopButtons(BuildContext context) {
    return _buildButtonsRow(
      context,
      compact: false,
    );
  }

  Widget _buildButtonsRow(BuildContext context, {required bool compact}) {
    final double height = compact ? 48 : 52;
    final EdgeInsets padding = compact
        ? const EdgeInsets.symmetric(horizontal: 20)
        : const EdgeInsets.symmetric(horizontal: 26);

    return Row(
      children: [
        SizedBox(
          height: height,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A00),
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
        SizedBox(
          height: height,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF8A00),
              side: const BorderSide(
                color: Color(0xFFFF8A00),
                width: 1.4,
              ),
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
