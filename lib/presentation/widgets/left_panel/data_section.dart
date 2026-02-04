import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volcano_data_provider.dart';
import '../common/section_header.dart';
import '../common/labeled_dropdown.dart';

/// Data section with comparison selector
class DataSection extends StatelessWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<VolcanoDataProvider>();
    final data = dataProvider.data;

    return Section(
      title: 'Data',
      icon: Icons.storage,
      children: [
        LabeledDropdown<String>(
          label: 'Comparison',
          value: data.selectedGroup.isNotEmpty
              ? data.selectedGroup
              : (data.groups.isNotEmpty ? data.groups.first : ''),
          items: data.groups,
          itemLabel: (g) => g,
          onChanged: dataProvider.selectGroup,
        ),
      ],
    );
  }
}
