import 'package:flutter/material.dart';
import '../widgets/image_button.dart';
import '../../utils/gateway_pin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    GatewayPin.ensureInitialized();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.97, end: 1.02).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _promptGatewayPin() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'ENTER GATEWAY PIN',
          style: TextStyle(
            color: Colors.orangeAccent,
            letterSpacing: 2,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '4-digit access code',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              final valid = await GatewayPin.verify(controller.text.trim());
              if (!ctx.mounted) return;
              if (valid) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Invalid PIN')),
                );
              }
            },
            child: const Text('UNLOCK'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gateway unlocked')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // TRUCK hero background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/TRUCK_HERO.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          // Dark scrim
          Container(color: Colors.black54),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Divergent Alliance',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.orangeAccent.withOpacity(0.7),
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
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'WX GRID READY',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.6,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Pulsing button cluster
                ScaleTransition(
                  scale: _scale,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ImageButton(
                          label: 'Weather Center',
                          onPressed: () =>
                              Navigator.pushNamed(context, '/weather'),
                        ),
                        const SizedBox(height: 16),
                        ImageButton(
                          label: 'Shop',
                          onPressed: () =>
                              Navigator.pushNamed(context, '/shop'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: ImageButton(
                    label: 'Gateway',
                    
                    onPressed: _promptGatewayPin,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
