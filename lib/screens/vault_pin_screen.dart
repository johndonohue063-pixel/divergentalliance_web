import 'package:flutter/material.dart';
import 'weather_center_pro.dart';

const Color _vaultOrange = Color(0xFFFF7A00);
const int _pinLength = 4;
const Set<String> _validPins = {'8883'};

class VaultPinScreen extends StatefulWidget {
  const VaultPinScreen({super.key});

  @override
  State<VaultPinScreen> createState() => _VaultPinScreenState();
}

class _VaultPinScreenState extends State<VaultPinScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double h = constraints.maxHeight;

          // Increase boxTopFactor to move the digits further DOWN,
          // decrease to move them up.
          const double boxTopFactor = 0.44;   // was ~0.41
          const double boxHeightFactor = 0.28;

          final double boxTop = h * boxTopFactor;
          final double boxHeight = h * boxHeightFactor;

          return Stack(
            fit: StackFit.expand,
            children: [
              // FULLSCREEN VAULT BACKGROUND
              Transform.scale(
                scale: 1.08, // tiny zoom to eat any edges / bands
                child: Image.asset(
                  'assets/images/vaultdoor.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),

              // PIN digits overlay (no black box now)
              Positioned(
                left: 0,
                right: 0,
                top: boxTop,
                height: boxHeight,
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).requestFocus(_focusNode);
                  },
                  child: Center(
                    child: SizedBox(
                      width: constraints.maxWidth * 0.75,
                      height: boxHeight,
                      child: Center(
                        child: _buildPinDigits(),
                      ),
                    ),
                  ),
                ),
              ),

              // Hidden TextField that actually receives keyboard input
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 1,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: _pinLength,
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    if (value.length > _pinLength) {
                      _controller.text = value.substring(0, _pinLength);
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: _controller.text.length),
                      );
                    }
                    setState(() {});
                    if (_controller.text.length == _pinLength) {
                      _onPinComplete(_controller.text);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPinDigits() {
  final text = _controller.text;

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(_pinLength, (index) {
      final char = index < text.length ? text[index] : '0';

      return SizedBox(
        width: 34,
        child: Center(
          child: Text(
            char,
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _vaultOrange,
              letterSpacing: 4,
              // Remove the heavy blur:
              // shadows: [
              //   Shadow(
              //     blurRadius: 12,
              //     color: _vaultOrange,
              //   ),
              // ],
            ),
          ),
        ),
      );
    }),
  );
}


  void _onPinComplete(String pin) {
    if (_validPins.contains(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to Divergent Alliances Weather Center'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WeatherCenterPro(),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      _controller.clear();
      setState(() {});
    }
  }
}
