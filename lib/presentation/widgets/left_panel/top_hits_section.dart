import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/enums.dart';
import '../../providers/plot_settings_provider.dart';
import '../../providers/volcano_data_provider.dart';
import '../common/section_header.dart';
import '../common/labeled_dropdown.dart';

/// Top hits section with ranking, top N, and gene selection
class TopHitsSection extends StatefulWidget {
  const TopHitsSection({super.key});

  @override
  State<TopHitsSection> createState() => _TopHitsSectionState();
}

class _TopHitsSectionState extends State<TopHitsSection> {
  final TextEditingController _topNController = TextEditingController();

  @override
  void dispose() {
    _topNController.dispose();
    super.dispose();
  }

  void _showGeneSelectionDialog(
    BuildContext context,
    List<String> allGenes,
    Set<String> selectedGenes,
    PlotSettingsProvider settingsProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => _GeneSelectionDialog(
        allGenes: allGenes,
        selectedGenes: selectedGenes,
        onSelectionChanged: (gene, isSelected) {
          if (isSelected) {
            settingsProvider.addSelectedGene(gene);
          } else {
            settingsProvider.removeSelectedGene(gene);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<PlotSettingsProvider>();
    final dataProvider = context.watch<VolcanoDataProvider>();
    final settings = settingsProvider.settings;
    final theme = Theme.of(context);

    // Update controller if value changed externally
    if (_topNController.text != settings.topN.toString()) {
      _topNController.text = settings.topN.toString();
    }

    return Section(
      title: 'Top Hits',
      icon: Icons.star,
      children: [
        // Ranking criterion dropdown
        LabeledDropdown<RankingCriterion>(
          label: 'Ranking',
          value: settings.rankingCriterion,
          items: RankingCriterion.values,
          itemLabel: (c) => c.displayName,
          onChanged: settingsProvider.setRankingCriterion,
        ),
        const SizedBox(height: AppSpacing.controlSpacing),
        // Top N input
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Show top',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 36,
              child: TextField(
                controller: _topNController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  hintText: '10',
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null && parsed >= 0) {
                    settingsProvider.setTopN(parsed);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.controlSpacing),
        // Gene selection
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Genes',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: () {
                  final allGenes = dataProvider.data.geneNames;
                  _showGeneSelectionDialog(
                    context,
                    allGenes,
                    settings.selectedGenes,
                    settingsProvider,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        settings.selectedGenes.isEmpty
                            ? 'Click to select genes...'
                            : '${settings.selectedGenes.length} gene(s) selected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: settings.selectedGenes.isEmpty
                              ? theme.hintColor
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: theme.iconTheme.color,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Selected genes chips
        if (settings.selectedGenes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: settings.selectedGenes.map((gene) {
              return Chip(
                label: Text(
                  gene,
                  style: theme.textTheme.labelSmall,
                ),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () =>
                    settingsProvider.removeSelectedGene(gene),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.only(left: 8),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// Dialog for multi-selecting genes from a list
class _GeneSelectionDialog extends StatefulWidget {
  final List<String> allGenes;
  final Set<String> selectedGenes;
  final void Function(String gene, bool isSelected) onSelectionChanged;

  const _GeneSelectionDialog({
    required this.allGenes,
    required this.selectedGenes,
    required this.onSelectionChanged,
  });

  @override
  State<_GeneSelectionDialog> createState() => _GeneSelectionDialogState();
}

class _GeneSelectionDialogState extends State<_GeneSelectionDialog> {
  late Set<String> _localSelection;
  final TextEditingController _filterController = TextEditingController();
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _localSelection = Set.from(widget.selectedGenes);
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<String> get _filteredGenes {
    if (_filterText.isEmpty) return widget.allGenes;
    final lower = _filterText.toLowerCase();
    return widget.allGenes.where((g) => g.toLowerCase().contains(lower)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredGenes = _filteredGenes;

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Select Genes')),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            // Filter text field
            TextField(
              controller: _filterController,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Filter genes...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _filterText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _filterController.clear();
                          setState(() => _filterText = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _filterText = value),
            ),
            const SizedBox(height: 8),
            // Selection info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_localSelection.length} selected',
                  style: theme.textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: _localSelection.isEmpty
                      ? null
                      : () {
                          setState(() {
                            for (final gene in _localSelection.toList()) {
                              widget.onSelectionChanged(gene, false);
                            }
                            _localSelection.clear();
                          });
                        },
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const Divider(),
            // Gene list
            Expanded(
              child: filteredGenes.isEmpty
                  ? Center(
                      child: Text(
                        'No genes found',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredGenes.length,
                      itemBuilder: (context, index) {
                        final gene = filteredGenes[index];
                        final isSelected = _localSelection.contains(gene);
                        return CheckboxListTile(
                          title: Text(
                            gene,
                            style: theme.textTheme.bodySmall,
                          ),
                          value: isSelected,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _localSelection.add(gene);
                              } else {
                                _localSelection.remove(gene);
                              }
                            });
                            widget.onSelectionChanged(gene, value ?? false);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
