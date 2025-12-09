import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// TODO: Replace this with your actual Render backend URL.
/// Example: 'https://da-wx-backend.onrender.com'
const String kBackendBaseUrl = 'https://YOUR-RENDER-BACKEND-URL-HERE';

/// TODO: Replace this with your actual day-level endpoint path.
/// Example: '/day-level' or '/api/day-level'
const String kDayLevelEndpointPath = '/api/day-level';

/// Simple filter model for the query we send to the backend.
/// You can expand this (state, segment, sku, etc.) as needed.
class DayLevelFilter {
  final DateTime date;
  final String? state;
  final String? city;

  const DayLevelFilter({
    required this.date,
    this.state,
    this.city,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{
      // backend receives ISO date (you can change this to whatever you use)
      'date': date.toIso8601String().split('T').first,
    };
    if (state != null && state!.isNotEmpty) {
      params['state'] = state!;
    }
    if (city != null && city!.isNotEmpty) {
      params['city'] = city!;
    }
    return params;
  }

  DayLevelFilter copyWith({
    DateTime? date,
    String? state,
    String? city,
  }) {
    return DayLevelFilter(
      date: date ?? this.date,
      state: state ?? this.state,
      city: city ?? this.city,
    );
  }
}

/// Data model for a single "day-level" row.
/// TODO: change the field names to match your backend’s JSON keys.
class DayLevelItem {
  final String id;
  final DateTime date;
  final String location; // could be "City, ST" or HFX unit, etc.
  final String summary;  // short text about the day
  final int? riskScore;  // nullable in case backend doesn’t send it
  final String? riskBand; // e.g. "Low", "Moderate", "Extreme"

  DayLevelItem({
    required this.id,
    required this.date,
    required this.location,
    required this.summary,
    this.riskScore,
    this.riskBand,
  });

  /// Be *defensive* about missing / weird data so it doesn't crash.
  factory DayLevelItem.fromJson(Map<String, dynamic> json) {
    // Try to parse a date from multiple possible fields.
    final dynamic rawDate = json['date'] ?? json['day'] ?? json['day_date'];
    DateTime parsedDate = DateTime.now();
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      // epoch seconds or ms – you may want to adjust this
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    return DayLevelItem(
      id: (json['id'] ?? json['day_id'] ?? '').toString(),
      location: (json['location'] ??
              json['city'] ??
              json['hfx_unit'] ??
              json['site'] ??
              'Unknown location')
          .toString(),
      summary: (json['summary'] ??
              json['headline'] ??
              json['description'] ??
              'No summary')
          .toString(),
      riskScore: _asNullableInt(json['risk_score'] ?? json['score']),
      riskBand: (json['risk_band'] ?? json['band'] ?? json['risk'])?.toString(),
      date: parsedDate,
    );
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

/// API client for fetching day-level data.
class DayLevelApi {
  const DayLevelApi();

  Future<List<DayLevelItem>> fetchDayLevels(DayLevelFilter filter) async {
    final uri = Uri.parse('$kBackendBaseUrl$kDayLevelEndpointPath')
        .replace(queryParameters: filter.toQueryParams());

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Day-level API error: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final body = response.body;
    if (body.isEmpty) {
      return <DayLevelItem>[];
    }

    final decoded = jsonDecode(body);

    List<dynamic> rawList;
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      // Handle typical shapes like { "items": [...] } or { "data": [...] }
      if (decoded['items'] is List) {
        rawList = decoded['items'] as List<dynamic>;
      } else if (decoded['data'] is List) {
        rawList = decoded['data'] as List<dynamic>;
      } else {
        throw Exception('Unexpected day-level JSON format: not a list.');
      }
    } else {
      throw Exception('Unexpected day-level JSON format.');
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(DayLevelItem.fromJson)
        .toList();
  }
}

/// Main Day Level screen – stateful so we can handle filters, loading, etc.
class DayLevelScreen extends StatefulWidget {
  const DayLevelScreen({super.key});

  @override
  State<DayLevelScreen> createState() => _DayLevelScreenState();
}

class _DayLevelScreenState extends State<DayLevelScreen> {
  final DayLevelApi _api = const DayLevelApi();

  late DayLevelFilter _filter;

  bool _isLoading = false;
  String? _errorMessage;
  List<DayLevelItem> _items = [];

  // Example state + city lists, you can replace with real ones or fetch from backend
  final List<String> _states = <String>[
    'All',
    'IL',
    'IN',
    'WI',
    'IA',
  ];
  String _selectedState = 'All';

  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = DayLevelFilter(date: DateTime.now());
    _loadData();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _api.fetchDayLevels(_filter);
      setState(() {
        _items = items;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _filter.date;
    final first = now.subtract(const Duration(days: 365));
    final last = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        _filter = _filter.copyWith(date: picked);
      });
      _loadData();
    }
  }

  void _onStateChanged(String? newValue) {
    if (newValue == null) return;
    setState(() {
      _selectedState = newValue;
      _filter = _filter.copyWith(
        state: newValue == 'All' ? null : newValue,
      );
    });
    _loadData();
  }

  void _onCityChanged(String value) {
    setState(() {
      _filter = _filter.copyWith(city: value.trim().isEmpty ? null : value);
    });
    // If you want to auto-refresh on city change, call _loadData() here.
  }

  void _onRefreshPressed() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_filter.date.year.toString().padLeft(4, '0')}-${_filter.date.month.toString().padLeft(2, '0')}-${_filter.date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day-Level View'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _onRefreshPressed,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Date picker
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(dateLabel),
                    ),

                    // State dropdown
                    DropdownButton<String>(
                      value: _selectedState,
                      onChanged: _onStateChanged,
                      items: _states
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s == 'All' ? 'All states' : s),
                            ),
                          )
                          .toList(),
                    ),

                    // City text field
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          hintText: 'City (optional)',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _isLoading ? null : _onRefreshPressed,
                          ),
                        ),
                        onChanged: _onCityChanged,
                        onSubmitted: (_) => _onRefreshPressed(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const LinearProgressIndicator()
                else if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  )
                else
                  Text(
                    'Showing ${_items.length} day-level entr${_items.length == 1 ? 'y' : 'ies'}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Results
          Expanded(
            child: _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          'Error loading data:\n$_errorMessage',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text('No day-level data for this filter.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _DayLevelTile(item: item);
      },
    );
  }
}

/// A single day-level row tile.
class _DayLevelTile extends StatelessWidget {
  final DayLevelItem item;

  const _DayLevelTile({required this.item});

  Color _riskColor(BuildContext context) {
    final theme = Theme.of(context);
    final score = item.riskScore ?? 0;
    final band = (item.riskBand ?? '').toLowerCase();

    if (band.contains('extreme') || score >= 80) {
      return Colors.redAccent;
    }
    if (band.contains('high') || score >= 60) {
      return Colors.orangeAccent;
    }
    if (band.contains('moderate') || score >= 40) {
      return Colors.amber;
    }
    if (band.contains('low') || score > 0) {
      return Colors.green;
    }

    // fallback neutral
    return theme.colorScheme.secondary.withOpacity(0.3);
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(context);

    final dateLabel =
        '${item.date.year.toString().padLeft(4, '0')}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: riskColor,
          child: Text(
            (item.riskScore ?? 0).toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          item.location,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel),
            const SizedBox(height: 4),
            Text(
              item.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: item.riskBand != null
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: riskColor),
                ),
                child: Text(
                  item.riskBand!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: riskColor,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
