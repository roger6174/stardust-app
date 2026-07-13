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

class CardBenefitsProvider {
  static final Map<String, List<CardBenefit>> _benefitsDb = {
    'hdfc millennia': [
      CardBenefit(title: 'Cashback', description: '5% on Amazon, Flipkart, Myntra, Swiggy', icon: Icons.sell_rounded),
      CardBenefit(title: 'Lounge Access', description: '8 complimentary domestic lounge visits per year', icon: Icons.flight_takeoff_rounded),
      CardBenefit(title: 'Dining', description: 'Up to 20% off at 2000+ premium restaurants', icon: Icons.restaurant_rounded),
      CardBenefit(title: 'Welcome Benefit', description: '1000 Cash points on joining', icon: Icons.card_giftcard_rounded),
    ],
    'axis magnus': [
      CardBenefit(title: 'Luxury Perks', description: 'Unlimited domestic lounge access + 8 international', icon: Icons.diamond_rounded),
      CardBenefit(title: 'Flight Voucher', description: 'Monthly voucher on achieving milestones', icon: Icons.confirmation_number_rounded),
      CardBenefit(title: 'Heathrow VIP', description: 'Meet & Assist service at select airports', icon: Icons.airport_shuttle_rounded),
      CardBenefit(title: 'Fine Dining', description: 'Axis Dining Delights - up to 25% off', icon: Icons.dinner_dining_rounded),
    ],
    'sbi elite': [
      CardBenefit(title: 'Reward Points', description: '5X points on Dining, Departmental stores', icon: Icons.stars_rounded),
      CardBenefit(title: 'Movie Tickets', description: 'Free movie tickets worth ₹6,000 annually', icon: Icons.movie_filter_rounded),
      CardBenefit(title: 'Priority Pass', description: 'Complimentary membership for international lounges', icon: Icons.vpn_key_rounded),
      CardBenefit(title: 'Golf Access', description: 'Complimentary rounds at select courses', icon: Icons.golf_course_rounded),
    ],
    'icici coral': [
      CardBenefit(title: 'Fuel Surcharge', description: '1% surcharge waiver at all HPCL pumps', icon: Icons.local_gas_station_rounded),
      CardBenefit(title: 'Buy 1 Get 1', description: 'BOGO on BookMyShow (up to 2 tickets free)', icon: Icons.local_activity_rounded),
      CardBenefit(title: 'Lounge Access', description: '1 complimentary domestic lounge visit per quarter', icon: Icons.airline_seat_recline_extra_rounded),
      CardBenefit(title: 'Dining Rewards', description: 'Culinary Treats program savings', icon: Icons.fastfood_rounded),
    ],
  };

  static List<CardBenefit> getBenefits(String name, String variant) {
    final searchKey = name.toLowerCase().trim();
    
    // Exact match for name
    if (_benefitsDb.containsKey(searchKey)) {
      return _benefitsDb[searchKey]!;
    }

    // Partial match for common parts
    for (var key in _benefitsDb.keys) {
      if (searchKey.contains(key)) {
        return _benefitsDb[key]!;
      }
    }

    // Default general benefits if no match found
    return [
      CardBenefit(title: 'Standard Security', description: 'Zero lost card liability & fraud protection', icon: Icons.security_rounded),
      CardBenefit(title: 'EMI Facilities', description: 'Convert big spends into easy monthly installments', icon: Icons.payment_rounded),
      CardBenefit(title: 'Contactless Pay', description: 'Secure tap and pay for rapid transactions', icon: Icons.contactless_rounded),
      CardBenefit(title: 'Digital Portal', description: 'Manage spending and limits through the app', icon: Icons.smartphone_rounded),
    ];
  }
}
