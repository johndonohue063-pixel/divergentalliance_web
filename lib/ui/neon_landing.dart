import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../screens/weather_center_pro.dart';
import '../pages/shop_under_construction.dart';

const _kNeon = Color(0xFFFF6A00);
const _kNeonSoft = Color(0xFFFFB44D);

class NeonLandingScreen extends StatefulWidget {
  const NeonLandingScreen({super.key});

  @override
  State<NeonLandingScreen> createState() => _NeonLandingScreenState();
}

class _NeonLandingScreenState extends State<NeonLandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _marqueeController;
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();

    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Hero video for web/desktop. If it fails, we fall back to a gradient.
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse('media/da_hero2.mp4'))
          ..setLooping(true)
          ..setVolume(0.0)
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() {
              _videoReady = true;
            });
            _videoController!.play();
          }).catchError((_) {
            // Ignore, keep gradient background
          });
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;

    return isLandscape ? _buildLandscape(context) : _buildPortrait(context);
  }

  // ---------------------------------------------------------------------------
  // Portrait: full-screen wallpaper + overlay
  // ---------------------------------------------------------------------------
  Widget _buildPortrait(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/wallpaper.png',
            fit: BoxFit.cover,
          ),
          _buildGlassOverlay(context, compact: true),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Landscape: hero video (or gradient) + overlay
  // ---------------------------------------------------------------------------
  Widget _buildLandscape(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoReady && _videoController != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF050608),
                    Color(0xFF0B111E),
                    Color(0xFF101C2A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          _buildGlassOverlay(context, compact: false),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared overlay: headline, buttons, right-side text, marquee
  // ---------------------------------------------------------------------------
  Widget _buildGlassOverlay(BuildContext context, {required bool compact}) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 800;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 24 : 64,
          vertical: compact ? 16 : 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBrandRow(),
            const Spacer(),
            _buildHeadlineBlock(isNarrow: isNarrow),
            const SizedBox(height: 32),
            _buildButtonRow(context, isNarrow: isNarrow),
            const SizedBox(height: 24),
            _buildOrientationLine(),
            const SizedBox(height: 24),
            _buildRightSideTagline(isNarrow: isNarrow),
            const SizedBox(height: 16),
            _buildMarquee(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBrandRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'DIVERGENT',
              style: TextStyle(
                letterSpacing: 6,
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'ALLIANCE',
              style: TextStyle(
                letterSpacing: 6,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeadlineBlock({required bool isNarrow}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OPERATIONAL WEATHER INTELLIGENCE',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 4,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'ELECTRIFY ',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [_kNeon, _kNeonSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(rect),
              child: const Text(
                'THE GRID',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: isNarrow ? double.infinity : 420,
          child: const Text(
            'Storm-hardening, utility supply, and real-time outage intelligence '
            'built for lineworkers, operations, and storm response teams.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonRow(BuildContext context, {required bool isNarrow}) {
    final primary = _NeonPrimaryButton(
      label: 'WEATHER CENTER',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const WeatherCenterPro(),
          ),
        );
      },
    );

    final secondary = _NeonHollowButton(
      label: 'SHOP',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ShopUnderConstruction(),
          ),
        );
      },
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          primary,
          const SizedBox(height: 12),
          secondary,
        ],
      );
    } else {
      return Row(
        children: [
          primary,
          const SizedBox(width: 16),
          secondary,
        ],
      );
    }
  }

  Widget _buildOrientationLine() {
    return const Text(
      'OPTIMIZED FOR DESKTOPS AND TABLETS IN LANDSCAPE. '
      'MOBILE PHONES USE THE IN-APP DIVERGENT WALLPAPER EXPERIENCE.',
      style: TextStyle(
        fontSize: 9,
        letterSpacing: 2.5,
        color: Colors.white60,
      ),
    );
  }

  Widget _buildRightSideTagline({required bool isNarrow}) {
    if (isNarrow) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          Text(
            'DIVERGENT ALLIANCE',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 3,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'UTILITY SUPPLY â€¢ STORM SERVICES â€¢ UTILITY R&D',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: _kNeonSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarquee() {
    const message =
        'Veteran-owned Â· IBEW-built Â· Powering the industry forward | '
        'Storm crews mobilizing 24/7 â€“ rapid power restoration when it matters most | '
        'Top-tier utility tools, PPE & conduit â€” trusted by linemen nationwide | '
        'Custom grounding & jumper assemblies â€” safety and reliability built in | '
        'From emergency storm response to full-service utility supply â€” weâ€™ve got you covered | '
        'Only union-built tooling & materials | Uncompromising quality and craftsmanship | '
        '400,000+ man-hours worked â€“ no accidents. Safety first, always. | '
        'Need conduit, storm-truck kits, or hot-stick tools? Contact us today.   ';

    return SizedBox(
      height: 24,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return AnimatedBuilder(
              animation: _marqueeController,
              builder: (context, child) {
                final dx = -width * _marqueeController.value;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: SizedBox(
                    width: width * 2,
                    child: Row(
                      children: const [
                        _MarqueeText(message),
                        SizedBox(width: 64),
                        _MarqueeText(message),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MarqueeText extends StatelessWidget {
  const _MarqueeText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.5,
        color: Colors.white70,
      ),
      maxLines: 1,
      overflow: TextOverflow.visible,
      softWrap: false,
    );
  }
}

// ---------------------------------------------------------------------------
// Neon buttons
// ---------------------------------------------------------------------------
class _NeonPrimaryButton extends StatelessWidget {
  const _NeonPrimaryButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              colors: [_kNeon, _kNeonSoft],
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: _kNeonSoft,
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeonHollowButton extends StatelessWidget {
  const _NeonHollowButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: _kNeonSoft, width: 1.4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kNeonSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
