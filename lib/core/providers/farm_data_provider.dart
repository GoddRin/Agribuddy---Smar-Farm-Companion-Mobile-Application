// Legacy tip provider — keep for dashboard
final List<Map<String, String>> _tips = [
  {'emoji': '💧', 'title': 'Water Early', 'body': 'Water your crops at 6–8 AM to minimize evaporation and fungal risk.'},
  {'emoji': '🌱', 'title': 'Check Soil pH', 'body': 'Most crops thrive at pH 6.0–7.0. Test your soil monthly.'},
  {'emoji': '🐛', 'title': 'Early Pest Detection', 'body': 'Check undersides of leaves weekly. Early detection saves the whole crop.'},
  {'emoji': '🌽', 'title': 'Crop Rotation', 'body': 'Rotating crops every season prevents soil depletion and reduces pests.'},
  {'emoji': '☀️', 'title': 'Mulching Saves Water', 'body': 'Add 2–3 inches of mulch around plants to retain moisture and reduce weeds.'},
  {'emoji': '🌾', 'title': 'Record Everything', 'body': 'Log every activity with date and time. Your logs are your farm\'s memory.'},
  {'emoji': '💰', 'title': 'Plan Before You Plant', 'body': 'Calculate seed, fertilizer, and labor costs before starting a new crop.'},
];

Map<String, String> get todaysTip {
  final idx = DateTime.now().day % _tips.length;
  return _tips[idx];
}
