import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class CardBenefit {
  final String title;
  final String description;
  final IconData icon;

  CardBenefit({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class CardBenefitsService {
  static const String _baseUrl = AppConfig.baseUrl;

  Future<List<CardBenefit>> fetchBenefits(String bank, String variant, String network) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/card-benefits'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bank': bank,
          'variant': variant,
          'network': network,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String rawBenefits = data['benefits'] ?? '';
        
        // Parse the AI's response (expecting 5 bullet points)
        return _parseAiBenefits(rawBenefits);
      }
    } catch (e) {
      debugPrint('AI Benefits Error: $e');
    }
    
    // Fallback to a placeholder or empty list if the service is down
    return [
      CardBenefit(
        title: 'Error Fetching Benefits', 
        description: 'Unable to connect to the Card Benefits service. Please try again later.', 
        icon: Icons.error_outline_rounded
      ),
    ];
  }

  List<CardBenefit> _parseAiBenefits(String text) {
    // Basic parser for bullet points
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final List<CardBenefit> benefits = [];

    for (var line in lines) {
      final cleanLine = line.replaceAll(RegExp(r'^[-*•]\s*'), '').trim();
      if (cleanLine.isNotEmpty) {
        // Try to split into title and description if a colon exists
        final parts = cleanLine.split(':');
        if (parts.length > 1) {
          benefits.add(CardBenefit(
            title: parts[0].trim(),
            description: parts.sublist(1).join(':').trim(),
            icon: _getIconForBenefit(parts[0].trim().toLowerCase()),
          ));
        } else {
          benefits.add(CardBenefit(
            title: 'Feature',
            description: cleanLine,
            icon: Icons.stars_rounded,
          ));
        }
      }
    }

    // Limit to 5 as per API prompt
    return benefits.take(5).toList();
  }

  IconData _getIconForBenefit(String title) {
    if (title.contains('lounge') || title.contains('airport') || title.contains('travel')) return Icons.flight_takeoff_rounded;
    if (title.contains('cashback') || title.contains('reward') || title.contains('points')) return Icons.sell_rounded;
    if (title.contains('dining') || title.contains('restaurant') || title.contains('food')) return Icons.restaurant_rounded;
    if (title.contains('movie') || title.contains('entertainment') || title.contains('ticket')) return Icons.movie_filter_rounded;
    if (title.contains('fuel') || title.contains('petrol')) return Icons.local_gas_station_rounded;
    if (title.contains('insurance') || title.contains('protection') || title.contains('safe')) return Icons.security_rounded;
    return Icons.star_rounded;
  }
}
