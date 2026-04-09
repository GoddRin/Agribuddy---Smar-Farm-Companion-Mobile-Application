import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/crop_provider.dart';
import '../../../core/localization/app_localizations.dart';

class CropsScreen extends ConsumerWidget {
  const CropsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crops = ref.watch(cropProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.t('My Crops')),
        actions: [
          TextButton.icon(
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(ref.t('Add')),
            onPressed: () => _openSheet(context, ref),
          )
        ],
      ),
      body: crops.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.sprout, size: 72, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(ref.t('No crops yet'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.grey[500])),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                  icon: const Icon(LucideIcons.plus),
                  label: Text(ref.t('Add Your First Crop')),
                  onPressed: () => _openSheet(context, ref)),
            ]).animate().fadeIn())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: crops.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _CropCard(crop: crops[i])
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i * 60))
                  .slideY(begin: 0.1),
            ),
      floatingActionButton: crops.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _openSheet(context, ref),
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(LucideIcons.plus, color: Colors.white))
          : null,
    );
  }

  static void _openSheet(BuildContext ctx, WidgetRef ref) =>
      showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _AddCropSheet(ref: ref),
      );
}

// ─── Crop Card ─────────────────────────────────────────────
class _CropCard extends ConsumerWidget {
  final Crop crop;
  const _CropCard({required this.crop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final health = crop.health;
    final hLabel = health >= 0.8
        ? ref.t('Good')
        : health >= 0.6
            ? ref.t('Fair')
            : ref.t('Poor');
    final hColor = health >= 0.8
        ? Colors.green
        : health >= 0.6
            ? Colors.orange
            : Colors.red;
    final harvest = crop.daysUntilHarvest;

    return Container(
      decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: crop.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(LucideIcons.sprout, color: crop.color, size: 26)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(crop.name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, fontSize: 18, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Row(children: [
                      _badge(hLabel, hColor, isLarge: true),
                      if (harvest != null) ...[
                        const SizedBox(width: 8),
                        _badge('🌾 $harvest', Colors.amber, isLarge: true)
                      ],
                    ]),
                    const SizedBox(height: 8),
                    Text('${crop.block} · ${ref.t(crop.stage)}',
                        style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ])),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 20),
                onSelected: (v) {
                  if (v == 'delete') {
                    ref.read(cropProvider.notifier).removeCrop(crop.id);
                  }
                  if (v == 'stage') {
                    _showStageDialog(context, ref, crop);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'stage',
                      child: Row(children: [
                        const Icon(LucideIcons.refreshCw, size: 16),
                        const SizedBox(width: 8),
                        Text(ref.t('Update Stage'))
                      ])),
                  PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(LucideIcons.trash2,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(ref.t('Remove'),
                            style: const TextStyle(color: Colors.red))
                      ])),
                ],
              ),
            ])),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(ref.t('Health'),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[500])),
                Text('${(health * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 12,
                        color: hColor,
                        fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      value: health,
                      backgroundColor: crop.color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(crop.color),
                      minHeight: 12)),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 14),
                    activeTrackColor: crop.color,
                    inactiveTrackColor: crop.color.withValues(alpha: 0.2),
                    thumbColor: crop.color),
                child: Slider(
                    value: health,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: (v) => ref
                        .read(cropProvider.notifier)
                        .updateHealth(crop.id, v)),
              ),
              Text(ref.t('Drag to update health'),
                  style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontSize: 10)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => _showStageDialog(context, ref, crop), child: Text(ref.t('Update Stage')))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: () {}, child: Text(ref.t('Log Activity')))),
              ]),
            ])),
      ]),
    );
  }

  Widget _badge(String text, Color color, {bool isLarge = false}) => Container(
        padding: EdgeInsets.symmetric(horizontal: isLarge ? 12 : 8, vertical: isLarge ? 6 : 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1)),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: isLarge ? 13 : 11, fontWeight: FontWeight.w900)),
      );

  static void _showStageDialog(BuildContext ctx, WidgetRef ref, Crop crop) {
    showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
              title: Text('${ref.t('Update Stage')} — ${crop.name}'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: growthStages
                      .map((s) => ListTile(
                            title: Text(ref.t(s)),
                            leading: Icon(
                                s == crop.stage
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: s == crop.stage
                                    ? const Color(0xFF16A34A)
                                    : Colors.grey),
                            onTap: () {
                              ref
                                  .read(cropProvider.notifier)
                                  .updateStage(crop.id, s);
                              Navigator.pop(ctx);
                            },
                          ))
                      .toList()),
            ));
  }
}

// ─── Add Crop Sheet ────────────────────────────────────────
class _AddCropSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddCropSheet({required this.ref});
  @override
  State<_AddCropSheet> createState() => _AddCropSheetState();
}

class _AddCropSheetState extends State<_AddCropSheet> {
  final _nameCtrl = TextEditingController();
  final _blockCtrl = TextEditingController();
  String _stage = growthStages[0];
  Color _color = cropColors[0];
  String _planted = DateTime.now().toIso8601String().substring(0, 10);
  String? _harvest;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _blockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isHarvest) async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030));
    if (d != null) {
      setState(() {
        if (isHarvest) {
          _harvest = d.toIso8601String().substring(0, 10);
        } else {
          _planted = d.toIso8601String().substring(0, 10);
        }
      });
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final block = _blockCtrl.text.trim();
    if (name.isEmpty || block.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill in all fields')));
      return;
    }
    widget.ref.read(cropProvider.notifier).addCrop(Crop(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          block: block,
          stage: _stage,
          health: 0.75,
          plantedDate: _planted,
          expectedHarvestDate: _harvest,
          colorValue: _color.value,
        ));
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$name added! 🌱')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(widget.ref.t('Add New Crop'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            TextField(
                controller: _nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                    labelText: widget.ref.t('Crop Name'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    prefixIcon: const Icon(LucideIcons.sprout, size: 22),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)))),
            const SizedBox(height: 16),
            TextField(
                controller: _blockCtrl,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                    labelText: widget.ref.t('Block / Location'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    prefixIcon: const Icon(LucideIcons.mapPin, size: 22),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)))),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _stage,
              decoration: InputDecoration(
                  labelText: widget.ref.t('Growth Stage'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  prefixIcon: const Icon(LucideIcons.trendingUp, size: 22),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16))),
              items: growthStages
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(widget.ref.t(s), style: const TextStyle(fontSize: 16))))
                  .toList(),
              onChanged: (v) => setState(() => _stage = v!),
            ),
            const SizedBox(height: 12),

            // Date pickers row
            Row(children: [
              Expanded(
                  child: _datePicker(widget.ref.t('Planted Date'), _planted,
                      () => _pickDate(false), widget.ref)),
              const SizedBox(width: 10),
              Expanded(
                  child: _datePicker(
                      widget.ref.t('Expected Harvest'),
                      _harvest ?? widget.ref.t('Not set'),
                      () => _pickDate(true),
                      widget.ref,
                      optional: true)),
            ]),
            const SizedBox(height: 12),

            // Color
            Text('Color',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
                spacing: 10,
                children: cropColors
                    .map((c) => GestureDetector(
                          onTap: () => setState(() => _color = c),
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _color == c
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2),
                                  boxShadow: _color == c
                                      ? [
                                          BoxShadow(
                                              color: c.withValues(alpha: 0.5),
                                              blurRadius: 8)
                                        ]
                                      : []),
                              child: _color == c
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : null),
                        ))
                    .toList()),
            const SizedBox(height: 20),

            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.plus, size: 24),
                  label: Text(widget.ref.t('Add Crop'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18))),
                  onPressed: _submit,
                )),
          ])),
    );
  }

  Widget _datePicker(
          String label, String value, VoidCallback onTap, WidgetRef ref,
          {bool optional = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
              borderRadius: BorderRadius.circular(16)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(LucideIcons.calendar,
                  size: 20,
                  color: optional && value == ref.t('Not set')
                      ? Colors.grey[400]
                      : const Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(value,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: optional && value == ref.t('Not set')
                              ? Colors.grey[400]
                              : null))),
            ]),
          ]),
        ),
      );
  }
}
