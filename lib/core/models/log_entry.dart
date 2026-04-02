const List<String> logTypes = [
  'Planting', 'Watering', 'Fertilizing',
  'Pest Control', 'Harvesting', 'Observation', 'Other',
];

class LogEntry {
  final String id;
  final String title;
  final String notes;
  final String type;
  final String date;   // yyyy-MM-dd
  final String time;   // HH:mm
  final String? photoPath;
  final String? cropId;
  final String? cropName;
  bool isSynced;

  LogEntry({
    required this.id,
    required this.title,
    required this.notes,
    required this.type,
    required this.date,
    required this.time,
    this.photoPath,
    this.cropId,
    this.cropName,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'notes': notes, 'type': type,
    'date': date, 'time': time, 'photoPath': photoPath,
    'cropId': cropId, 'cropName': cropName, 'isSynced': isSynced,
  };

  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(
    id: j['id'], title: j['title'], notes: j['notes'] ?? '',
    type: j['type'] ?? 'Other', date: j['date'], time: j['time'] ?? '08:00',
    photoPath: j['photoPath'], cropId: j['cropId'], cropName: j['cropName'],
    isSynced: j['isSynced'] ?? false,
  );
}
