class TransactionTypes {
  static const all = 'all';
  static const income = 'income';
  static const expense = 'expense';
}

class SyncStatusValues {
  static const synced = 'synced';
  static const pendingCreate = 'pendingCreate';
  static const pendingUpdate = 'pendingUpdate';
  static const pendingDelete = 'pendingDelete';
  static const failed = 'failed';
}

const incomeCategories = [
  'Salary',
  'Freelance',
  'Allowance',
  'Bonus',
  'Other Income',
];

const expenseCategories = [
  'Food',
  'Transport',
  'Shopping',
  'Entertainment',
  'College',
  'Health',
  'Bills',
  'Other Expense',
];

const transactionCategories = [...incomeCategories, ...expenseCategories];
