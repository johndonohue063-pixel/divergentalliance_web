import 'package:flutter/material.dart';
import 'package:divergent_alliance/pages/weather_results.dart';

class RunReportProcessingScreen extends StatefulWidget {
  final bool isNational;
  final String region;
  final String state;
  final int hoursOut;

  const RunReportProcessingScreen({
    super.key,
    required this.isNational,
    required this.region,
    required this.state,
    required this.hoursOut,
  });

  @override
  State<RunReportProcessingScreen> createState() =>
      _RunReportProcessingScreenState();
}

class _RunReportProcessingScreenState extends State<RunReportProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // Wait until after the first frame before navigating so Navigator isn't locked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToResults();
    });
  }

  void _goToResults() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WeatherResults(
          isNational: widget.isNational,
          region: widget.region,
          state: widget.state,
          hoursOut: widget.hoursOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/runreportclickscreen.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay with spinner only (no text)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.orange,
                  strokeWidth: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
