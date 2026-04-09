import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/models/log_entry.dart';
import '../../../core/providers/logs_provider.dart';
import '../../../core/providers/crop_provider.dart';
import '../../../core/localization/app_localizations.dart';

class FieldLogsScreen extends ConsumerStatefulWidget {
  const FieldLogsScreen({super.key});
  @override
  ConsumerState<FieldLogsScreen> createState() => _FieldLogsScreenState();
}

class _FieldLogsScreenState extends ConsumerState<FieldLogsScreen> {
  String _search = '';
  String? _filterType;

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logsProvider);
    final theme = Theme.of(context);

    final filtered = logs.where((l) {
      final matchSearch = l.title.toLowerCase().contains(_search.toLowerCase()) ||
          l.notes.toLowerCase().contains(_search.toLowerCase());
      final matchType = _filterType == null || l.type == _filterType;
      return matchSearch && matchType;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.t('Farm Logs')),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _openAddSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: ref.t('Search logs...'),
                prefixIcon: const Icon(LucideIcons.search, size: 22, color: Color(0xFF16A34A)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true,
                fillColor: theme.cardTheme.color,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 60,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              children: [
                _chip(ref.t('All'), _filterType == null, () => setState(() => _filterType = null)),
                ...logTypes.map((t) => _chip(ref.t(t), _filterType == t, () => setState(() => _filterType = t))),
              ],
            ),
          ),
          // Logs list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(LucideIcons.clipboardList, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(ref.t(_search.isNotEmpty ? 'No matching logs' : 'No logs yet'),
                        style: TextStyle(color: Colors.grey[500])),
                      if (_search.isEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(LucideIcons.plus),
                          label: Text(ref.t('Add First Log')),
                          onPressed: () => _openAddSheet(context, ref),
                        ),
                      ],
                    ]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _LogCard(log: filtered[i])
                        .animate().fadeIn(delay: Duration(milliseconds: i * 50)).slideY(begin: 0.1),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context, ref),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static void _openAddSheet(BuildContext ctx, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddLogSheet(ref: ref),
    );
  }
}

// ─── Log Card ──────────────────────────────────────────────
class _LogCard extends ConsumerWidget {
  final LogEntry log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final typeColor = _typeColor(log.type);
    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(logsProvider.notifier).deleteLog(log.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(_typeIcon(log.type), color: typeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(log.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: typeColor.withValues(alpha: 0.3))),
                child: Text(ref.t(log.type), style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(LucideIcons.calendar, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(log.date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(width: 10),
              Icon(LucideIcons.clock, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(log.time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              if (log.cropName != null) ...[
                const SizedBox(width: 10),
                Icon(LucideIcons.sprout, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(log.cropName!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ]),
            if (log.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(log.notes, style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[500], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (log.photoPath != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(LucideIcons.image, size: 12, color: Colors.blue[400]),
                const SizedBox(width: 4),
                Text(ref.t('Photo attached'), style: TextStyle(color: Colors.blue[400], fontSize: 11)),
              ]),
            ],
          ])),
        ]),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Planting': return Colors.green;
      case 'Watering': return Colors.blue;
      case 'Fertilizing': return Colors.orange;
      case 'Pest Control': return Colors.red;
      case 'Harvesting': return Colors.amber;
      case 'Observation': return Colors.teal;
      default: return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Planting': return LucideIcons.sprout;
      case 'Watering': return LucideIcons.droplets;
      case 'Fertilizing': return LucideIcons.leaf;
      case 'Pest Control': return LucideIcons.bug;
      case 'Harvesting': return LucideIcons.scissors;
      case 'Observation': return LucideIcons.eye;
      default: return LucideIcons.fileText;
    }
  }
}

// ─── Add Log Sheet ─────────────────────────────────────────
class _AddLogSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddLogSheet({required this.ref});
  @override
  State<_AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<_AddLogSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = logTypes[0];
  String _date = DateTime.now().toIso8601String().substring(0, 10);
  String _time = '';
  String? _photoPath;
  String? _cropId;
  String? _cropName;

  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _time = _fmtTime(TimeOfDay.now());
  }

  @override
  void dispose() { _titleCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (d != null) setState(() => _date = d.toIso8601String().substring(0, 10));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _time = _fmtTime(t));
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _photoPath = img.path);
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a title'))); return; }
    widget.ref.read(logsProvider.notifier).addLog(LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, notes: _notesCtrl.text.trim(),
      type: _type, date: _date, time: _time,
      photoPath: _photoPath, cropId: _cropId, cropName: _cropName,
    ));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.ref.t('Log')} "$title" ${widget.ref.t('saved!')}')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crops = widget.ref.watch(cropProvider);
    return Padding(
      padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(widget.ref.t('Add Farm Log'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Title
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: widget.ref.t('Activity Title'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              prefixIcon: const Icon(LucideIcons.fileText, size: 22),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),

          // Type dropdown
          // ignore: deprecated_member_use
          DropdownButtonFormField<String>(
            value: _type,
            decoration: InputDecoration(
              labelText: widget.ref.t('Activity Type'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              prefixIcon: const Icon(LucideIcons.tag, size: 22),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            items: logTypes.map((t) => DropdownMenuItem(value: t, child: Text(widget.ref.t(t), style: const TextStyle(fontSize: 16)))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 16),

          // Date + Time row
          Row(children: [
            Expanded(child: _pickerTile(icon: LucideIcons.calendar, label: _date, onTap: _pickDate, theme: theme)),
            const SizedBox(width: 10),
            Expanded(child: _pickerTile(icon: LucideIcons.clock, label: _time, onTap: _pickTime, theme: theme)),
          ]),
          const SizedBox(height: 12),

          // Linked crop
          if (crops.isNotEmpty) DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: widget.ref.t('Linked Crop (optional)'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              prefixIcon: const Icon(LucideIcons.sprout, size: 22),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text(widget.ref.t('None'), style: const TextStyle(fontSize: 16))),
              ...crops.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 16)))),
            ],
            onChanged: (v) {
              setState(() {
                _cropId = v;
                _cropName = v == null ? null : crops.firstWhere((c) => c.id == v).name;
              });
            },
          ),
          if (crops.isNotEmpty) const SizedBox(height: 16),

          // Notes
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: '${widget.ref.t('Notes')} (${widget.ref.t('optional')})',
              alignLabelWithHint: true,
              prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 50), child: Icon(LucideIcons.stickyNote, size: 22)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),

          // Photo
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey[50],
                border: Border.all(color: theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Icon(LucideIcons.camera, size: 24, color: _photoPath != null ? const Color(0xFF16A34A) : (theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600])),
                const SizedBox(width: 14),
                Text(_photoPath != null ? widget.ref.t('Photo attached ✓') : '${widget.ref.t('Attach Photo')} (${widget.ref.t('optional')})',
                  style: TextStyle(color: _photoPath != null ? const Color(0xFF16A34A) : Colors.grey[600], fontSize: 15, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            icon: const Icon(LucideIcons.save, size: 24),
            label: Text(widget.ref.t('Save Log'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _submit,
          )),
        ]),
      ),
    );
  }

  Widget _pickerTile({required IconData icon, required String label, required VoidCallback onTap, required ThemeData theme}) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: const Color(0xFF16A34A)),
          const SizedBox(width: 10),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}
