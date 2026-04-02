const List<String> taskCategories = [
  'Irrigation', 'Fertilizer', 'Spraying',
  'Harvesting', 'Planting', 'Inspection', 'Other',
];

const List<String> repeatOptions = ['None', 'Daily', 'Weekly'];

class TaskItem {
  final String id;
  final String title;
  final String category;
  final String dueDate;  // yyyy-MM-dd
  final String dueTime;  // HH:mm
  final String? cropId;
  final String? cropName;
  bool isCompleted;
  final String repeat;

  TaskItem({
    required this.id,
    required this.title,
    required this.category,
    required this.dueDate,
    required this.dueTime,
    this.cropId,
    this.cropName,
    this.isCompleted = false,
    this.repeat = 'None',
  });

  bool get isOverdue {
    if (isCompleted) return false;
    final due = DateTime.tryParse('$dueDate $dueTime:00');
    if (due == null) return false;
    return due.isBefore(DateTime.now());
  }

  bool get isDueToday {
    final today = DateTime.now();
    final due = DateTime.tryParse(dueDate);
    if (due == null) return false;
    return due.year == today.year && due.month == today.month && due.day == today.day;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'category': category,
    'dueDate': dueDate, 'dueTime': dueTime,
    'cropId': cropId, 'cropName': cropName,
    'isCompleted': isCompleted, 'repeat': repeat,
  };

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
    id: j['id'], title: j['title'], category: j['category'] ?? 'Other',
    dueDate: j['dueDate'], dueTime: j['dueTime'] ?? '08:00',
    cropId: j['cropId'], cropName: j['cropName'],
    isCompleted: j['isCompleted'] ?? false, repeat: j['repeat'] ?? 'None',
  );
}
