import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../hive/hive_service.dart';

// ─── Crop Model ─────────────────────────────────────────────
class Crop {
  final String id;
  final String name;
  final String block;
  final String stage;
  final double health;
  final String plantedDate;
  final String? expectedHarvestDate;
  final int colorValue;

  Color get color => Color(colorValue);

  const Crop({
    required this.id,
    required this.name,
    required this.block,
    required this.stage,
    required this.health,
    required this.plantedDate,
    this.expectedHarvestDate,
    required this.colorValue,
  });

  Crop copyWith({
    String? name, String? block, String? stage, double? health,
    String? plantedDate, String? expectedHarvestDate, int? colorValue,
  }) => Crop(
    id: id, name: name ?? this.name, block: block ?? this.block,
    stage: stage ?? this.stage, health: health ?? this.health,
    plantedDate: plantedDate ?? this.plantedDate,
    expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
    colorValue: colorValue ?? this.colorValue,
  );

  String? get daysUntilHarvest {
    if (expectedHarvestDate == null) return null;
    final harvest = DateTime.tryParse(expectedHarvestDate!);
    if (harvest == null) return null;
    final diff = harvest.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today!';
    return '$diff days';
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'block': block, 'stage': stage,
    'health': health, 'plantedDate': plantedDate,
    'expectedHarvestDate': expectedHarvestDate, 'colorValue': colorValue,
  };

  factory Crop.fromJson(Map<String, dynamic> j) => Crop(
    id: j['id'], name: j['name'], block: j['block'], stage: j['stage'],
    health: (j['health'] as num).toDouble(), plantedDate: j['plantedDate'],
    expectedHarvestDate: j['expectedHarvestDate'],
    // ignore: deprecated_member_use
    colorValue: j['colorValue'] ?? Colors.green.value,
  );
}

// ─── Predefined colors ─────────────────────────────────────
final List<Color> cropColors = [
  Colors.green, Colors.orange, Colors.red, Colors.purple,
  Colors.teal, Colors.indigo, Colors.amber, Colors.cyan,
];

// ─── Growth Stages ─────────────────────────────────────────
const List<String> growthStages = [
  'Seedling', 'Vegetative', 'Flowering',
  'Fruiting', 'Established', 'Ready to Harvest',
];

// ─── Crop Provider ─────────────────────────────────────────
class CropNotifier extends StateNotifier<List<Crop>> {
  CropNotifier() : super([]) { _load(); }

  void _load() {
    final saved = HiveService.getCrops();
    if (saved.isNotEmpty) {
      state = saved;
    } else {
      // Default sample crops
      final defaults = [
        // ignore: deprecated_member_use
        Crop(id: '1', name: 'Corn', block: 'Block A', stage: 'Vegetative', health: 0.85, plantedDate: '2026-03-01', expectedHarvestDate: '2026-06-01', colorValue: Colors.orange.value),
        // ignore: deprecated_member_use
        Crop(id: '2', name: 'Tomato', block: 'Block B', stage: 'Flowering', health: 0.70, plantedDate: '2026-03-10', expectedHarvestDate: '2026-05-15', colorValue: Colors.red.value),
        // ignore: deprecated_member_use
        Crop(id: '3', name: 'Pechay', block: 'Block C', stage: 'Seedling', health: 0.80, plantedDate: '2026-03-25', expectedHarvestDate: '2026-04-20', colorValue: Colors.teal.value),
      ];
      state = defaults;
      for (final c in defaults) {
        HiveService.saveCrop(c);
      }
    }
  }

  void addCrop(Crop crop) {
    state = [...state, crop];
    HiveService.saveCrop(crop);
  }

  void removeCrop(String id) {
    state = state.where((c) => c.id != id).toList();
    HiveService.deleteCrop(id);
  }

  void updateHealth(String id, double health) {
    state = [for (final c in state) if (c.id == id) c.copyWith(health: health) else c];
    final updated = state.firstWhere((c) => c.id == id);
    HiveService.saveCrop(updated);
  }

  void updateStage(String id, String stage) {
    state = [for (final c in state) if (c.id == id) c.copyWith(stage: stage) else c];
    final updated = state.firstWhere((c) => c.id == id);
    HiveService.saveCrop(updated);
  }

  String get overallHealth {
    if (state.isEmpty) return 'No Crops';
    final avg = state.map((c) => c.health).reduce((a, b) => a + b) / state.length;
    if (avg >= 0.8) return 'Thriving';
    if (avg >= 0.6) return 'Fair';
    return 'Needs Attention';
  }
}

final cropProvider = StateNotifierProvider<CropNotifier, List<Crop>>(
  (ref) => CropNotifier(),
);
