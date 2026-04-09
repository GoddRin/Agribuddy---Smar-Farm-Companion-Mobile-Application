import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/task_item.dart';
import '../../../../core/providers/tasks_provider.dart';
import '../../../../core/providers/crop_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/audio_service.dart';

class AddTaskSheet extends StatefulWidget {
  final WidgetRef ref;
  final DateTime? initialDate;

  const AddTaskSheet({super.key, required this.ref, this.initialDate});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  String _category = taskCategories[0];
  late String _dueDate;
  String _dueTime = '';
  String _repeat = 'None';
  String? _cropId;
  String? _cropName;

  @override
  void initState() {
    super.initState();
    _dueDate = (widget.initialDate ?? DateTime.now()).toIso8601String().substring(0, 10);
    _dueTime = _fmt(TimeOfDay.now());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) return;
    widget.ref.read(tasksProvider.notifier).addTask(TaskItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleCtrl.text.trim(),
          category: _category,
          dueDate: _dueDate,
          dueTime: _dueTime,
          cropId: _cropId,
          cropName: _cropName,
          repeat: _repeat,
        ));
    widget.ref.read(audioServiceProvider).playSfx(SfxType.success);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.ref.t('Task added!'))));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crops = widget.ref.watch(cropProvider);
    return Padding(
      padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text(widget.ref.t('Add Task'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
            controller: _titleCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
                labelText: widget.ref.t('Task Name'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                prefixIcon: const Icon(LucideIcons.checkCircle, size: 22),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: InputDecoration(
              labelText: widget.ref.t('Category'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              prefixIcon: const Icon(LucideIcons.tag, size: 22),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          items: taskCategories
              .map((c) => DropdownMenuItem(value: c, child: Text(widget.ref.t(c), style: const TextStyle(fontSize: 16))))
              .toList(),
          onChanged: (v) => setState(() => _category = v!),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _pickerBox(LucideIcons.calendar, _dueDate, () async {
            final d = await showDatePicker(
                context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
            if (d != null) setState(() => _dueDate = d.toIso8601String().substring(0, 10));
          })),
          const SizedBox(width: 10),
          Expanded(
              child: _pickerBox(LucideIcons.clock, _dueTime, () async {
            final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
            if (t != null) setState(() => _dueTime = _fmt(t));
          })),
        ]),
        const SizedBox(height: 12),
        if (crops.isNotEmpty)
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
                labelText: widget.ref.t('Linked Crop (optional)'),
                prefixIcon: const Icon(LucideIcons.sprout, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
            items: [
              DropdownMenuItem(value: null, child: Text(widget.ref.t('None'))),
              ...crops.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
            ],
            onChanged: (v) => setState(() {
              _cropId = v;
              _cropName = v == null ? null : crops.firstWhere((c) => c.id == v).name;
            }),
          ),
        if (crops.isNotEmpty) const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _repeat,
          decoration: InputDecoration(
              labelText: widget.ref.t('Repeat'),
              prefixIcon: const Icon(LucideIcons.refreshCw, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
          items: repeatOptions.map((r) => DropdownMenuItem(value: r, child: Text(widget.ref.t(r)))).toList(),
          onChanged: (v) => setState(() => _repeat = v!),
        ),
        const SizedBox(height: 20),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.plus),
              label: Text(widget.ref.t('Add Task')),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _submit,
            )),
      ])),
    );
  }

  Widget _pickerBox(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13))
        ]),
      ),
    );
  }
}
