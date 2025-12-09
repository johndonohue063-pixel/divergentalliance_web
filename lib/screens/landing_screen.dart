import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

const Color _brandOrange = Color(0xFFFF8C2A);
const Color _brandBg = Colors.black;

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _videoController;
  bool _videoInitialized = false;

  late final AnimationController _neonController;

  @override
  void initState() {
    super.initState();

    // Neon text animation controller
    _neonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Hero video controller
    _videoController = VideoPlayerController.asset('assets/video/da_hero.mp4')
      ..setLooping(true)
      ..setVolume(0.0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _videoInitialized = true;
        });
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _neonController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final orientation = media.orientation;

    final bool isWide = size.width >= 900;
    final bool showVideo =
        _videoInitialized && (isWide || orientation == Orientation.landscape);
    final bool isCompact =
        size.width < 600 || orientation == Orientation.portrait;

    final Widget background = showVideo
        ? FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController.value.size.width,
              height: _videoController.value.size.height,
              child: VideoPlayer(_videoController),
            ),
          )
        : Image.asset(
            'assets/images/truck.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black),
          );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _brandBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/icons/da_logo.png',
              height: 28,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            const Text(
              'DIVERGENT ALLIANCE',
              style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          background,
          // Dark scrim for contrast over video / photo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x8F000000),
                  Color(0xFF000000),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: isCompact
                  ? _buildCompactContent(context)
                  : _buildWideContent(context),
            ),
          ),
        ],
      ),
    );
  }

  // --------- WIDE / LANDSCAPE (desktop & tablets) ----------
  Widget _buildWideContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        const Text(
          'OPERATIONAL WEATHER INTELLIGENCE',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 3,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        _NeonScanningText(
          controller: _neonController,
          text: 'ELECTRIFY THE GRID',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            color: _brandOrange,
          ),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          width: 520,
          child: Text(
            'Storm-hardened utility supply and real-time outage intelligence '
            'built for lineworkers, operations, and storm response teams.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.white70,
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildCtas(isCompact: false),
        const SizedBox(height: 32),
      ],
    );
  }

  // --------- COMPACT / PORTRAIT (phones) ----------
  Widget _buildCompactContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        const Text(
          'OPERATIONAL WEATHER INTELLIGENCE',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2.5,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        _NeonScanningText(
          controller: _neonController,
          text: 'ELECTRIFY THE GRID',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: _brandOrange,
          ),
        ),
        const SizedBox(height: 10),
        const SizedBox(
          width: 360,
          child: Text(
            'Storm crews mobilizing 24/7. Utility supply, PPE, and outage intel '
            'optimized for phones and tablets in the field.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.white70,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildCtas(isCompact: true),
        const SizedBox(height: 16),
      ],
    );
  }

  // --------- CTA buttons (Weather / Shop) ----------
  Widget _buildCtas({required bool isCompact}) {
    final double height = isCompact ? 52 : 56;
    final double spacing = isCompact ? 12 : 16;

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Open Weather Center',
            child: SizedBox(
              height: height,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/weather'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandOrange,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
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
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Open Shop',
            child: SizedBox(
              height: height,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/shop'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
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
          ),
        ),
      ],
    );
  }
}

// --------- Neon / digital scan text ----------
class _NeonScanningText extends StatelessWidget {
  final AnimationController controller;
  final String text;
  final TextStyle style;

  const _NeonScanningText({
    required this.controller,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final Animation<double> glow = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: glow,
      builder: (context, child) {
        final Color base = style.color ?? _brandOrange;
        final double t = glow.value;

        return Text(
          text,
          style: style.copyWith(
            color: Color.lerp(base.withOpacity(0.6), base, t),
            shadows: [
              Shadow(
                color: base.withOpacity(0.25 * t),
                blurRadius: 4 + 6 * t,
              ),
              Shadow(
                color: base.withOpacity(0.55 * t),
                blurRadius: 12 + 14 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
