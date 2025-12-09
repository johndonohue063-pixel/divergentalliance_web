import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _videoController;
  bool _videoReady = false;

  late final AnimationController _glowController;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    // Neon “breathing” glow for the headline.
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glow = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    // Hero video – muted + looping so it can autoplay on web.
    _videoController = VideoPlayerController.asset('assets/video/da_hero.mp4')
      ..setLooping(true)
      ..setVolume(0.0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoReady = true);
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height >= size.width;
    final isPhoneWidth = size.width < 700;

    // Narrow portrait = phone → static wallpaper + CTA layout only.
    if (isPortrait && isPhoneWidth) {
      return const _MobileLanding();
    }

    // Desktop / tablet / landscape → video + neon hero.
    return _DesktopLanding(
      videoController: _videoController,
      videoReady: _videoReady,
      glow: _glow,
    );
  }
}

// =================== DESKTOP / LANDSCAPE HERO ===================

class _DesktopLanding extends StatelessWidget {
  const _DesktopLanding({
    required this.videoController,
    required this.videoReady,
    required this.glow,
  });

  final VideoPlayerController videoController;
  final bool videoReady;
  final Animation<double> glow;

  static const Color _brandOrange = Color(0xFFFF6A00);
  static const Color _brandYellow = Color(0xFFFFC300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            Image.asset(
              'assets/icons/da_logo.png',
              height: 28,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            const Text(
              'Divergent Alliance',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Hero video background.
          if (videoReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: videoController.value.size.width,
                height: videoController.value.size.height,
                child: VideoPlayer(videoController),
              ),
            )
          else
            // Fallback still image while video loads.
            Image.asset(
              'assets/images/truck.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),

          // Dark scrim to keep text readable.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Center neon text block.
          Center(
            child: AnimatedBuilder(
              animation: glow,
              builder: (context, _) {
                final strength = glow.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'OPERATIONAL WEATHER INTELLIGENCE',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 4,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [_brandOrange, _brandYellow],
                        ).createShader(bounds);
                      },
                      child: Text(
                        'ELECTRIFY THE GRID',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: _brandOrange.withOpacity(0.8 * strength),
                              blurRadius: 24 + 8 * strength,
                            ),
                            Shadow(
                              color: _brandYellow.withOpacity(0.6 * strength),
                              blurRadius: 40 + 10 * strength,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Storm response, material supply, and utility R&D for the crews that keep the grid alive.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom copy + CTAs.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 3,
                    child: Text(
                      'Trusted by linemen nationwide. Custom grounding & jumper assemblies, PPE, and storm tools with industrial‑grade safety and reliability.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Flexible(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/weather');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandOrange,
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text(
                              'WEATHER CENTER',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/shop');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white70),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text(
                              'SHOP',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
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

// =================== MOBILE PORTRAIT HERO ===================

class _MobileLanding extends StatelessWidget {
  const _MobileLanding();

  static const Color _brandOrange = Color(0xFFFF6A00);
  static const Color _onBrandOrange = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/icons/da_logo.png',
              height: 24,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            const Text(
              'Divergent Alliance',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/truck.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OPERATIONAL WEATHER INTELLIGENCE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2.5,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'ELECTRIFY\nTHE GRID',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Storm-hardening, utility supply, and real-time outage intelligence built for linemen, operations, and storm response teams.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud),
                      label: const Text('WEATHER CENTER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandOrange,
                        foregroundColor: _onBrandOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/weather');
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.storefront),
                      label: const Text('SHOP'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.8),
                        ),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/shop');
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Optimized for desktops and tablets in landscape. Mobile phones use the in‑app Divergent wallpaper experience.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: Colors.white.withOpacity(0.7),
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
