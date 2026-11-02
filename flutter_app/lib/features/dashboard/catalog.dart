import 'dart:convert';

import 'package:flutter/services.dart';

class DashboardCatalog {
  const DashboardCatalog({
    required this.quotes,
    required this.scales,
    required this.resources,
    required this.videos,
  });
  final List<Map<String, dynamic>> quotes, scales, videos;
  final Map<String, dynamic> resources;
  static Future<DashboardCatalog> load() async {
    final names = [
      'daily_reminders',
      'scale_catalog',
      'resource_copy',
      'relax_videos',
    ];
    final values = await Future.wait(
      names.map(
        (name) async =>
            jsonDecode(await rootBundle.loadString('assets/data/$name.json')),
      ),
    );
    return DashboardCatalog(
      quotes: (values[0] as List).cast<Map<String, dynamic>>(),
      scales: (values[1] as List).cast<Map<String, dynamic>>(),
      resources: values[2] as Map<String, dynamic>,
      videos: (values[3] as List).cast<Map<String, dynamic>>(),
    );
  }
}
