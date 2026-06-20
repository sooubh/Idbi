import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/models/savings_goal.dart';
import 'package:student_fin_os/models/investment_holding.dart';
import 'package:student_fin_os/services/in_memory_db.dart';

enum DemoProfileType {
  conservative,
  moderate,
  aggressive,
}

class DemoSeeder {
  static void seed(String userId, DemoProfileType type) {
    InMemoryDb.clear();

    final DateTime now = DateTime.now().toUtc();

    switch (type) {
      case DemoProfileType.conservative:
        _seedConservative(userId, now);
        break;
      case DemoProfileType.moderate:
        _seedModerate(userId, now);
        break;
      case DemoProfileType.aggressive:
        _seedAggressive(userId, now);
        break;
    }

    InMemoryDb.hasSeeded = true;
  }

  static void _seedConservative(String userId, DateTime now) {
    InMemoryDb.accounts.addAll([
      Account(
        id: 'con_acc_1',
        userId: userId,
        name: 'HDFC Savings Account',
        type: AccountType.bank,
        provider: 'HDFC Bank',
        balance: 45000.0,
        isActive: true,
        icon: 'account_balance',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      Account(
        id: 'con_acc_2',
        userId: userId,
        name: 'UPI Liquid Wallet',
        type: AccountType.upi,
        provider: 'GPay',
        balance: 5000.0,
        isActive: true,
        icon: 'phone_android',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
    ]);

    InMemoryDb.investments.addAll([
      InvestmentHolding(
        id: 'con_inv_1',
        userId: userId,
        name: 'SBI 1-Yr Fixed Deposit',
        category: 'Fixed Deposits',
        investedAmount: 150000.0,
        currentValue: 156200.0,
        returnsPercent: 4.13,
        lastUpdated: now,
      ),
      InvestmentHolding(
        id: 'con_inv_2',
        userId: userId,
        name: 'ICICI Prudential Debt Mutual Fund',
        category: 'Mutual Funds',
        investedAmount: 50000.0,
        currentValue: 52400.0,
        returnsPercent: 4.80,
        lastUpdated: now,
      ),
      InvestmentHolding(
        id: 'con_inv_3',
        userId: userId,
        name: 'Gold ETF (Sovereign Gold Bonds)',
        category: 'Gold',
        investedAmount: 30000.0,
        currentValue: 33100.0,
        returnsPercent: 10.33,
        lastUpdated: now,
      ),
      InvestmentHolding(
        id: 'con_inv_4',
        userId: userId,
        name: 'TCS bluechip Shares',
        category: 'Equities',
        investedAmount: 15000.0,
        currentValue: 15800.0,
        returnsPercent: 5.33,
        lastUpdated: now,
      ),
    ]);

    InMemoryDb.transactions.addAll([
      FinanceTransaction(
        id: 'con_tx_1',
        userId: userId,
        accountId: 'con_acc_1',
        title: 'Monthly Salary Credits',
        amount: 85000.0,
        type: TransactionType.income,
        category: 'salary',
        source: 'Corporate Direct Deposit',
        channel: 'bank_transfer',
        transactionAt: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      FinanceTransaction(
        id: 'con_tx_2',
        userId: userId,
        accountId: 'con_acc_1',
        title: 'SIP Auto-Deduct (Debt Fund)',
        amount: 10000.0,
        type: TransactionType.expense,
        category: 'investment',
        source: 'Standing Instruction',
        channel: 'bank_transfer',
        transactionAt: now.subtract(const Duration(days: 4)),
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      FinanceTransaction(
        id: 'con_tx_3',
        userId: userId,
        accountId: 'con_acc_1',
        title: 'House Rent Outlay',
        amount: 22000.0,
        type: TransactionType.expense,
        category: 'bills',
        source: 'HDFC NetBanking',
        channel: 'bank_transfer',
        transactionAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      FinanceTransaction(
        id: 'con_tx_4',
        userId: userId,
        accountId: 'con_acc_2',
        title: 'BigBasket Grocery Billing',
        amount: 3200.0,
        type: TransactionType.expense,
        category: 'grocery',
        source: 'HDFC UPI Scan',
        channel: 'upi',
        transactionAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      FinanceTransaction(
        id: 'con_tx_5',
        userId: userId,
        accountId: 'con_acc_2',
        title: 'Electricity Utility Bill',
        amount: 2450.0,
        type: TransactionType.expense,
        category: 'bills',
        source: 'HDFC UPI Auto',
        channel: 'upi',
        transactionAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    InMemoryDb.goals.addAll([
      SavingsGoal(
        id: 'con_g_1',
        userId: userId,
        title: '6-Month Emergency Buffer',
        targetAmount: 120000.0,
        savedAmount: 95000.0,
        deadline: now.add(const Duration(days: 90)),
        status: GoalStatus.active,
        priority: 1,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
    ]);
  }

  static void _seedModerate(String userId, DateTime now) {
    InMemoryDb.accounts.addAll([
      Account(
        id: 'mod_acc_1',
        userId: userId,
        name: 'ICICI checking account',
        type: AccountType.bank,
        provider: 'ICICI Bank',
        balance: 32000.0,
        isActive: true,
        icon: 'account_balance',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      Account(
        id: 'mod_acc_2',
        userId: userId,
        name: 'PhonePe checking wallet',
        type: AccountType.upi,
        provider: 'PhonePe',
        balance: 6200.0,
        isActive: true,
        icon: 'phone_android',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
    ]);

    InMemoryDb.investments.addAll([
      InvestmentHolding(
        id: 'mod_inv_1',
        userId: userId,
        name: 'HDFC Index Mutual Fund (Nifty 50)',
        category: 'Mutual Funds',
        investedAmount: 120000.0,
        currentValue: 134200.0,
        returnsPercent: 11.83,
        lastUpdated: now,
      ),
      InvestmentHolding(
        id: 'mod_inv_2',
        userId: userId,
        name: 'Reliance & Infosys Shares',
        category: 'Equities',
        investedAmount: 90000.0,
        currentValue: 101500.0,
        returnsPercent: 12.78,
        lastUpdated: now,
      ),
      InvestmentHolding(
        id: 'mod_inv_3',
        userId: userId,
        name: 'SBI Gold ETF tracker',
        category: 'Gold',
        investedAmount: 30000.0,
        currentValue: 33100.0,
        returnsPercent: 10.33,
        lastUpdated: now,
      ),
      InvestmentHolding(
        id: 'mod_inv_4',
        userId: userId,
        name: 'Post Office FD deposit',
        category: 'Fixed Deposits',
        investedAmount: 60000.0,
        currentValue: 62800.0,
        returnsPercent: 4.67,
        lastUpdated: now,
      ),
    ]);

    InMemoryDb.transactions.addAll([
      FinanceTransaction(
        id: 'mod_tx_1',
        userId: userId,
        accountId: 'mod_acc_1',
        title: 'Monthly Salary Payout',
        amount: 92000.0,
        type: TransactionType.income,
        category: 'salary',
        source: 'Corporate salary direct credit',
        channel: 'bank_transfer',
        transactionAt: now.subtract(const Duration(days: 6)),
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
      FinanceTransaction(
        id: 'mod_tx_2',
        userId: userId,
        accountId: 'mod_acc_1',
        title: 'Auto SIP Nifty 50 Index Mutual Fund',
        amount: 15000.0,
        type: TransactionType.expense,
        category: 'investment',
        source: 'Standing auto-debit instruction',
        channel: 'bank_transfer',
        transactionAt: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      FinanceTransaction(
        id: 'mod_tx_3',
        userId: userId,
        accountId: 'mod_acc_1',
        title: 'Home Flat Rent Outlay',
        amount: 25000.0,
        type: TransactionType.expense,
        category: 'bills',
        source: 'ICICI NetBanking flat pay',
        channel: 'bank_transfer',
        transactionAt: now.subtract(const Duration(days: 4)),
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      FinanceTransaction(
        id: 'mod_tx_4',
        userId: userId,
        accountId: 'mod_acc_2',
        title: 'Amazon Online Purchase',
        amount: 4890.0,
        type: TransactionType.expense,
        category: 'shopping',
        source: 'ICICI UPI Wallet checkout',
        channel: 'upi',
        transactionAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      FinanceTransaction(
        id: 'mod_tx_5',
        userId: userId,
        accountId: 'mod_acc_2',
        title: 'Swiggy Family Dinner billing',
        amount: 1890.0,
        type: TransactionType.expense,
        category: 'food',
        source: 'PhonePe UPI pay',
        channel: 'upi',
        transactionAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ]);

    InMemoryDb.goals.addAll([
      SavingsGoal(
        id: 'mod_g_1',
        userId: userId,
        title: 'Balanced Retirement SIP fund',
        targetAmount: 500000.0,
        savedAmount: 230000.0,
        deadline: now.add(const Duration(days: 365)),
        status: GoalStatus.active,
        priority: 1,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
    ]);
  }

  static void _seedAggressive(String userId, DateTime now) {
    InMemoryDb.accounts.addAll([
      Account(
        id: 'agg_acc_1',
        userId: userId,
        name: 'Kotak Active Checking account',
        type: AccountType.bank,
        provider: 'Kotak Bank',
        balance: 18000.0,
        isActive: true,
        icon: 'account_balance',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      Account(
        id: 'agg_acc_2',
        userId: userId,
        name: 'UPI Fast Wallet',
        type: AccountType.upi,
        provider: 'Paytm',
        balance: 2400.0,
        isActive: true,
        icon: 'phone_android',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
    ]);

    InMemoryDb.investments.addAll([
      InvestmentHolding(
        id: 'agg_inv_1',
        userId: userId,
        name: 'Kotak Small Cap Mutual Fund',
        category: 'Mutual Funds',
        investedAmount: 80000.0,
        currentValue: 98400.0,
        returnsPercent: 23.00,
        lastUpdated: now,
      ),
      InvestmentHolding(
        id: 'agg_inv_2',
        userId: userId,
        name: 'High-Growth Tech Equities (TCS, Tata Motors, Jio)',
        category: 'Equities',
        investedAmount: 210000.0,
        currentValue: 254200.0,
        returnsPercent: 21.05,
        lastUpdated: now,
      ),
      InvestmentHolding(
        id: 'agg_inv_3',
        userId: userId,
        name: 'Gold Fund tracking ETF',
        category: 'Gold',
        investedAmount: 15000.0,
        currentValue: 16500.0,
        returnsPercent: 10.00,
        lastUpdated: now,
      ),
    ]);

    InMemoryDb.transactions.addAll([
      FinanceTransaction(
        id: 'agg_tx_1',
        userId: userId,
        accountId: 'agg_acc_1',
        title: 'Monthly Salary credits',
        amount: 110000.0,
        type: TransactionType.income,
        category: 'salary',
        source: 'Corporate paycheck deposit',
        channel: 'bank_transfer',
        transactionAt: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      FinanceTransaction(
        id: 'agg_tx_2',
        userId: userId,
        accountId: 'agg_acc_1',
        title: 'SIP Auto-Deduct (Small Cap Fund)',
        amount: 25000.0,
        type: TransactionType.expense,
        category: 'investment',
        source: 'Autodebit mandate instruction',
        channel: 'bank_transfer',
        transactionAt: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      FinanceTransaction(
        id: 'agg_tx_3',
        userId: userId,
        accountId: 'agg_acc_1',
        title: 'Home Flat Rent payment',
        amount: 30000.0,
        type: TransactionType.expense,
        category: 'bills',
        source: 'Kotak mobile bank flat pay',
        channel: 'bank_transfer',
        transactionAt: now.subtract(const Duration(days: 4)),
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      FinanceTransaction(
        id: 'agg_tx_4',
        userId: userId,
        accountId: 'agg_acc_2',
        title: 'Fine Dining Restaurant checkout',
        amount: 3500.0,
        type: TransactionType.expense,
        category: 'food',
        source: 'Paytm Wallet Scan pay',
        channel: 'upi',
        transactionAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      FinanceTransaction(
        id: 'agg_tx_5',
        userId: userId,
        accountId: 'agg_acc_2',
        title: 'Online Shopping Gadgets checkout',
        amount: 8200.0,
        type: TransactionType.expense,
        category: 'shopping',
        source: 'GPay UPI scan checkout',
        channel: 'upi',
        transactionAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ]);

    InMemoryDb.goals.addAll([
      SavingsGoal(
        id: 'agg_g_1',
        userId: userId,
        title: 'High-Yield Alpha Growth Fund SIP',
        targetAmount: 800000.0,
        savedAmount: 320000.0,
        deadline: now.add(const Duration(days: 365)),
        status: GoalStatus.active,
        priority: 1,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
    ]);
  }
}
