import 'package:flutter/material.dart';
import '../ui/da_brand.dart';

class WxPinGateScreen extends StatefulWidget {
  const WxPinGateScreen({super.key});

  @override
  State<WxPinGateScreen> createState() => _WxPinGateScreenState();
}

class _WxPinGateScreenState extends State<WxPinGateScreen> {
  final List<String> _entered = <String>[];
  String _error = '';

  final List<String> _allowedPins = <String>['8883'];

  void _tap(String digit) {
    setState(() {
      _error = '';
      if (digit == 'back') {
        if (_entered.isNotEmpty) {
          _entered.removeLast();
        }
      } else if (_entered.length < 4) {
        _entered.add(digit);
      }
      if (_entered.length == 4) {
        final String pin = _entered.join();
        if (_allowedPins.contains(pin)) {
          Navigator.pushReplacementNamed(context, '/weather_center');
        } else {
          _error = 'Access denied';
          _entered.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String code = _entered.join().padRight(4, '*');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Center Access'),
      ),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 32),
          Text(
            'Command Pin Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DABrand.orange,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            code,
            style: const TextStyle(
              fontSize: 36,
              letterSpacing: 12,
            ),
          ),
          const SizedBox(height: 8),
          if (_error.isNotEmpty)
            Text(
              _error,
              style: const TextStyle(color: Colors.redAccent),
            ),
          const SizedBox(height: 32),
          Expanded(
            child: _PinPad(onTap: _tap),
          ),
        ],
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  final void Function(String) onTap;

  const _PinPad({required this.onTap});

  Widget _buildKey(String label, {String? send}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: InkWell(
          onTap: () => onTap(send ?? label),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF161616),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: DABrand.orange.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(children: <Widget>[_buildKey('1'), _buildKey('2'), _buildKey('3')]),
        Row(children: <Widget>[_buildKey('4'), _buildKey('5'), _buildKey('6')]),
        Row(children: <Widget>[_buildKey('7'), _buildKey('8'), _buildKey('9')]),
        Row(
          children: <Widget>[
            const Spacer(),
            _buildKey('0'),
            _buildKey('BACK', send: 'back'),
          ],
        ),
      ],
    );
  }
}
