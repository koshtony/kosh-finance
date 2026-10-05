import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/time_range.dart';

class TimeRangeSelector extends StatelessWidget {
  final TimeRange selected;
  final ValueChanged<TimeRange> onChanged;

  const TimeRangeSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: TimeRange.values.map((r) {
          final isSelected = r == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(r.label),
              selected: isSelected,
              onSelected: (_) => onChanged(r),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : kBrandDark,
              ),
              selectedColor: kBrandColor,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? kBrandColor : const Color(0xFFEEE3CC)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }
}
