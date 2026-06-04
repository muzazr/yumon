import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/transaction_constants.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_view.dart';
import '../models/transaction_model.dart';
import 'transaction_controller.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.localId});

  final Id? localId;

  bool get isEdit => localId != null;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  String _type = TransactionTypes.expense;
  String _category = expenseCategories.first;
  DateTime _date = DateTime.now();
  bool _initialized = false;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.localId == null
        ? const AsyncValue<TransactionModel?>.data(null)
        : ref.watch(transactionByIdProvider(widget.localId!));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: existing.when(
        data: (transaction) {
          if (!_initialized && transaction != null) {
            _hydrate(transaction);
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionTypes.income,
                          label: Text('Income'),
                          icon: Icon(Icons.arrow_downward_rounded),
                        ),
                        ButtonSegment(
                          value: TransactionTypes.expense,
                          label: Text('Expense'),
                          icon: Icon(Icons.arrow_upward_rounded),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (value) {
                        setState(() {
                          _type = value.first;
                          _category = _categories.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _amount,
                      label: 'Amount',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final amount = double.tryParse(value ?? '');
                        if (amount == null || amount <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _title,
                      label: 'Title',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _category = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          initialDate: _date,
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(_date.toString().split(' ').first),
                            ),
                            const Icon(Icons.calendar_month_outlined),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _note,
                      label: 'Note (optional)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Save Transaction',
                      icon: Icons.save_rounded,
                      onPressed: _save,
                    ),
                    if (widget.isEdit) ...[
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Delete Transaction',
                        icon: Icons.delete_outline_rounded,
                        isDanger: true,
                        onPressed: _delete,
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Saved locally first. Sync from Home or Settings when online.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const LoadingView(),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  List<String> get _categories =>
      _type == TransactionTypes.income ? incomeCategories : expenseCategories;

  void _hydrate(TransactionModel transaction) {
    _initialized = true;
    _title.text = transaction.title;
    _amount.text = transaction.amount.toStringAsFixed(0);
    _note.text = transaction.note ?? '';
    _type = transaction.type;
    _category = transaction.category;
    _date = transaction.date;
  }

  TransactionInput _input() {
    return TransactionInput(
      title: _title.text.trim(),
      amount: double.parse(_amount.text),
      type: _type,
      category: _category,
      date: _date,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = await ref.read(transactionRepositoryProvider.future);
    if (widget.localId == null) {
      await repository.createTransaction(_input());
    } else {
      await repository.updateTransaction(widget.localId!, _input());
    }
    _refresh();
    if (mounted) context.go('/transactions');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This change is saved locally and synced later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final repository = await ref.read(transactionRepositoryProvider.future);
    await repository.deleteTransaction(widget.localId!);
    _refresh();
    if (mounted) context.go('/transactions');
  }

  void _refresh() {
    ref.invalidate(transactionListProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(monthlySummaryProvider);
  }
}
