import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/transaction_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../presentation/transaction_controller.dart';

class TransactionFilterBar extends ConsumerWidget {
  const TransactionFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FilterChipButton(
                label: DateFormatter.month(filter.month),
                icon: Icons.calendar_month_outlined,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    initialDate: filter.month,
                  );
                  if (picked != null) {
                    ref.read(transactionFilterProvider.notifier).state = filter
                        .copyWith(month: DateTime(picked.year, picked.month));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final type in const [
              TransactionTypes.all,
              TransactionTypes.income,
              TransactionTypes.expense,
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_typeLabel(type)),
                    selected: filter.type == type,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: filter.type == type
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) {
                      ref.read(transactionFilterProvider.notifier).state =
                          filter.copyWith(type: type);
                    },
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: filter.category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Categories'),
            ),
            ...transactionCategories.map(
              (item) => DropdownMenuItem(value: item, child: Text(item)),
            ),
          ],
          onChanged: (value) {
            ref.read(transactionFilterProvider.notifier).state = filter
                .copyWith(category: value, clearCategory: value == null);
          },
        ),
      ],
    );
  }

  String _typeLabel(String value) {
    if (value == TransactionTypes.income) return 'Income';
    if (value == TransactionTypes.expense) return 'Expense';
    return 'All';
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}
