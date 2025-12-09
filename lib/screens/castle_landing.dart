import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/da_brand.dart';

// ======= GLOBAL NEON CONSTANTS ===============================================

const Color kDaNeon = Color(0xFFFF6A00);
const List<Shadow> kDaNeonGlow = [
  Shadow(
    color: Color(0xFFFFA040),
    blurRadius: 22,
  ),
  Shadow(
    color: Color(0xFFFF6A00),
    blurRadius: 10,
  ),
  Shadow(
    color: Colors.white24,
    blurRadius: 0,
  ),
];

// ======= MAIN LANDING SCREEN =================================================

class CastleLanding extends StatefulWidget {
  const CastleLanding({super.key});

  @override
  State<CastleLanding> createState() => _CastleLandingState();
}

class _CastleLandingState extends State<CastleLanding>
    with SingleTickerProviderStateMixin {
  late final AnimationController _marqueeController;
  int _headlineIndex = 0;
  Timer? _headlineTimer;

  static const List<String> _intelHeadlines = [
    'STORM CREWS MOBILIZING 24/7',
    'UTILITY SUPPLY • TOOLS • PPE • CONDUIT',
    'CUSTOM GROUNDING & JUMPER ASSEMBLIES',
    '400,000+ MAN-HOURS • ZERO ACCIDENTS',
  ];

  static const String _marqueeText =
      'Veteran-owned · IBEW-built · Powering the Industry Forward | '
      'Storm crews mobilizing 24/7 – rapid power restoration when it matters most | '
      'Top-tier utility tools, PPE & conduit — trusted by linemen nationwide | '
      'Custom grounding & jumper assemblies — safety and reliability built in | '
      'From emergency storm response to full-service utility supply — we’ve got you covered | '
      'Only union-built tooling & materials | Uncompromising quality and craftsmanship — Build Masters | '
      '400,000+ man-hours worked – no accidents. Safety first, always. | '
      'Need conduit, storm-truck kits, or hot-stick tools? Contact us today.';

  @override
  void initState() {
    super.initState();

    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _headlineTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      setState(() {
        _headlineIndex = (_headlineIndex + 1) % _intelHeadlines.length;
      });
    });
  }

  @override
  void dispose() {
    _headlineTimer?.cancel();
    _marqueeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isNarrow = size.width < 720;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dark gradient for readability over video / wallpaper.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xE6000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 20 : 40,
                vertical: isNarrow ? 16 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(isNarrow),
                  const Spacer(),
                  _buildIntelBlock(isNarrow),
                  const SizedBox(height: 28),
                  _buildButtonsRow(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildBottomMarquee(),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isNarrow) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Wordmark – no black boxes.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DIVERGENT',
              style: GoogleFonts.wallpoet(
                fontSize: isNarrow ? 22 : 26,
                letterSpacing: 6,
                color: kDaNeon,
                shadows: kDaNeonGlow,
              ),
            ),
            Text(
              'ALLIANCE',
              style: GoogleFonts.wallpoet(
                fontSize: isNarrow ? 22 : 26,
                letterSpacing: 6,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isNarrow)
          Text(
            'STORM RESPONSE • UTILITY SUPPLY • R&D',
            style: GoogleFonts.robotoCondensed(
              fontSize: 13,
              letterSpacing: 2.0,
              color: Colors.white70,
            ),
          ),
      ],
    );
  }

  Widget _buildIntelBlock(bool isNarrow) {
    final baseTitleSize = isNarrow ? 24.0 : 36.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ELECTRIFY THE GRID.',
          style: GoogleFonts.wallpoet(
            fontSize: baseTitleSize,
            letterSpacing: 3.5,
            color: kDaNeon,
            height: 1.2,
            shadows: kDaNeonGlow,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Storm crews, utility supply, and R&D — built by veterans, '
          'powered by IBEW craftsmen.',
          style: GoogleFonts.robotoMono(
            fontSize: isNarrow ? 11 : 13,
            height: 1.5,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 550),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _intelHeadlines[_headlineIndex],
            key: ValueKey(_intelHeadlines[_headlineIndex]),
            style: GoogleFonts.robotoMono(
              fontSize: isNarrow ? 12 : 14,
              letterSpacing: 1.2,
              color: kDaNeon,
              shadows: kDaNeonGlow,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonsRow() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _NeonButton(
          labelTop: 'WX OPS',
          labelMain: 'Weather Center PRO',
          labelBottom: 'Live situational intelligence',
          onTap: () => Navigator.of(context).pushNamed('/weather'),
        ),
        _NeonButton(
          labelTop: 'SUPPLY',
          labelMain: 'Shop',
          labelBottom: 'Store wiring in progress',
          onTap: () => Navigator.of(context).pushNamed('/shop'),
        ),
        _NeonButton(
          labelTop: 'R&D',
          labelMain: 'Build Lab',
          labelBottom: 'Tooling, prototypes, concepts',
          onTap: () {
            // placeholder for future R&D screen
          },
        ),
      ],
    );
  }

  Widget _buildBottomMarquee() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 8,
      child: SizedBox(
        height: 26,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _marqueeController,
            builder: (context, child) {
              final value = _marqueeController.value;
              final dx = 1.0 - 2.0 * value; // 1 -> -1
              return FractionalTranslation(
                translation: Offset(dx, 0),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _marqueeText,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: kDaNeon,
                  shadows: kDaNeonGlow,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ======= NEON BUTTON =========================================================

class _NeonButton extends StatefulWidget {
  const _NeonButton({
    required this.labelTop,
    required this.labelMain,
    required this.labelBottom,
    required this.onTap,
  });

  final String labelTop;
  final String labelMain;
  final String labelBottom;
  final VoidCallback onTap;

  @override
  State<_NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<_NeonButton> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : (_hovering ? 1.03 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: scale,
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovering ? Colors.white : kDaNeon,
                width: 1.4,
              ),
              gradient: LinearGradient(
                colors: _hovering
                    ? const [
                        Color(0xFF111111),
                        Color(0xFF1E1E1E),
                      ]
                    : const [
                        Color(0xFF080808),
                        Color(0xFF141414),
                      ],
              ),
              boxShadow: _hovering
                  ? [
                      BoxShadow(
                        color: kDaNeon.withOpacity(0.7),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.9),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.labelTop,
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    letterSpacing: 2.0,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.labelMain,
                  style: GoogleFonts.wallpoet(
                    fontSize: 18,
                    letterSpacing: 2.4,
                    color: kDaNeon,
                    shadows: kDaNeonGlow,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.labelBottom,
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
