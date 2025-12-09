// lib/screens/report_screen.dart
// AUTO-GENERATED: tools/flutter_wire_backend.ps1
import 'package:flutter/material.dart';
import '../api.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future =
        fetchStateReport(state: "TX", hours: 36, metric: "wind", threshold: 22);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("State Report")),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: "));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text("No rows"));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final r = items[i] as Map<String, dynamic>;
              final county = (r["county"] ?? "").toString();
              final state = (r["state"] ?? "").toString();
              final wind = (r["wind_max"] ?? 0).toString();
              return ListTile(
                title: Text(", "),
                subtitle: Text("Max wind: "),
              );
            },
          );
        },
      ),
    );
  }
}
