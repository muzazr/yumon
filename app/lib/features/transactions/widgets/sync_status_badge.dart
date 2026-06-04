import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/transaction_constants.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final synced = status == SyncStatusValues.synced;
    final failed = status == SyncStatusValues.failed;
    final color = failed
        ? AppColors.expense
        : synced
        ? AppColors.income
        : AppColors.primary;
    final label = failed
        ? 'Failed'
        : synced
        ? 'Synced'
        : 'Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
