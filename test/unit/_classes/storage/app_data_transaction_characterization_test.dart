// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

// ignore_for_file: type=lint

import 'dart:async';
import 'package:app_finance/_classes/herald/app_sync.dart';
import 'package:app_finance/_classes/math/bill_recalculation.dart';
import 'package:app_finance/_classes/math/budget_prediction.dart';
import 'package:app_finance/_classes/math/budget_recalculation.dart';
import 'package:app_finance/_classes/math/goal_recalculation.dart';
import 'package:app_finance/_classes/math/invoice_recalculation.dart';
import 'package:app_finance/_classes/math/total_recalculation.dart';
import 'package:app_finance/_classes/herald/app_locale.dart';
import 'package:app_finance/_classes/storage/app_data.dart';
import 'package:app_finance/_classes/storage/app_data_store.dart';
import 'package:app_finance/_classes/storage/app_preferences.dart';
import 'package:app_finance/_classes/storage/di/app_data_dependencies.dart';
import 'package:app_finance/_classes/structure/account_app_data.dart';
import 'package:app_finance/_classes/structure/bill_app_data.dart';
import 'package:app_finance/_classes/structure/budget_app_data.dart';
import 'package:app_finance/_classes/structure/currency/exchange.dart';
import 'package:app_finance/_classes/structure/goal_app_data.dart';
import 'package:app_finance/_classes/structure/invoice_app_data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_currency_picker/flutter_currency_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

class _MockAppSync extends Mock implements AppSync {}

class _CapturingAppSync extends _MockAppSync {
  void Function(String)? callback;

  @override
  void follow(Type type, Function callback) {
    this.callback = callback as void Function(String);
  }
}

class _InlineNoopStore implements AppDataExchangeStore {
  @override
  dynamic add(value, [String? uuid]) => value;

  @override
  dynamic getByUuid(String uuid, [bool isClone = true]) => null;
}

class _FakeExchange extends Exchange {
  _FakeExchange() : super(store: _InlineNoopStore());

  @override
  Currency? getDefaultCurrency() => null;

  @override
  double reform(double? amount, Currency? origin, Currency? target) => 1.0;
}

class _NoopTransactionLogGateway implements AppDataTransactionLogGateway {
  @override
  bool add(AppDataStore store, String line, bool isEncrypted, [bool onlyNew = false]) => true;

  @override
  Future<bool> load(AppDataStore store) async => true;

  @override
  void save(dynamic content) {}
}

class _ThrowingTransactionLogGateway extends _NoopTransactionLogGateway {
  @override
  bool add(AppDataStore store, String line, bool isEncrypted, [bool onlyNew = false]) {
    throw StateError('stream-crash');
  }
}

class _PendingLoadTransactionLogGateway extends _NoopTransactionLogGateway {
  final Completer<bool> _completer = Completer<bool>();

  @override
  Future<bool> load(AppDataStore store) => _completer.future;
}

class _NoopTotalRecalculation extends TotalRecalculation {
  _NoopTotalRecalculation(Exchange exchange) : super(exchange: exchange);

  @override
  Future<void> updateTotal(AppDataType type, dynamic summary, dynamic hashTable) async {}

  @override
  void updateGoals(dynamic goalList, double initTotal, double total) {}
}

class _SpyBillRecalculation extends BillRecalculation {
  _SpyBillRecalculation({required BillAppData change}) : super(change: change);

  int updateAccountCalls = 0;
  int updateBudgetCalls = 0;
  AccountAppData? lastAccountChange;
  AccountAppData? lastAccountInitial;
  BudgetAppData? lastBudgetChange;
  BudgetAppData? lastBudgetInitial;

  @override
  BillRecalculation updateAccount(AccountAppData accountChange, AccountAppData? accountInitial) {
    updateAccountCalls++;
    lastAccountChange = accountChange;
    lastAccountInitial = accountInitial;
    return this;
  }

  @override
  BillRecalculation updateBudget(BudgetAppData budgetChange, BudgetAppData? budgetInitial) {
    updateBudgetCalls++;
    lastBudgetChange = budgetChange;
    lastBudgetInitial = budgetInitial;
    return this;
  }
}

class _SpyInvoiceRecalculation extends InvoiceRecalculation {
  _SpyInvoiceRecalculation(InvoiceAppData change) : super(change);

  int updateAccountCalls = 0;
  final List<bool> reverseValues = [];
  final List<AccountAppData?> accountInitials = [];

  @override
  void updateAccount(AccountAppData accountChange, AccountAppData? accountInitial, [bool reverse = false]) {
    updateAccountCalls++;
    reverseValues.add(reverse);
    accountInitials.add(accountInitial);
  }
}

class _FactoryCrashOnBill extends _ConfigurableFactory {
  _FactoryCrashOnBill({
    required super.exchange,
  });

  @override
  BillRecalculation createBillRecalculation({
    required BillAppData change,
    BillAppData? initial,
  }) {
    throw StateError('bill-factory-crash');
  }
}

class _FactoryCrashOnInvoice extends _ConfigurableFactory {
  _FactoryCrashOnInvoice({
    required super.exchange,
  });

  @override
  InvoiceRecalculation createInvoiceRecalculation(
    InvoiceAppData change, [
    InvoiceAppData? initial,
  ]) {
    throw StateError('invoice-factory-crash');
  }
}

class _ConfigurableFactory implements AppDataCollaboratorsFactory {
  _ConfigurableFactory({
    required this.exchange,
    this.bill,
    this.invoice,
  });

  final Exchange exchange;
  final _SpyBillRecalculation? bill;
  final _SpyInvoiceRecalculation? invoice;

  @override
  Exchange createExchange(AppDataStore store) => exchange;

  @override
  TotalRecalculation createTotalRecalculation(Exchange exchange) => _NoopTotalRecalculation(exchange);

  @override
  BillRecalculation createBillRecalculation({
    required BillAppData change,
    BillAppData? initial,
  }) {
    if (bill != null) {
      bill!
        ..change = change
        ..initial = initial
        ..exchange = exchange;
      return bill!;
    }
    return BillRecalculation(change: change, initial: initial)..exchange = exchange;
  }

  @override
  InvoiceRecalculation createInvoiceRecalculation(
    InvoiceAppData change, [
    InvoiceAppData? initial,
  ]) {
    if (invoice != null) {
      invoice!
        ..change = change
        ..initial = initial
        ..exchange = exchange;
      return invoice!;
    }
    return InvoiceRecalculation(change, initial)..exchange = exchange;
  }

  @override
  BudgetRecalculation createBudgetRecalculation({
    required BudgetAppData change,
    BudgetAppData? initial,
  }) {
    return BudgetRecalculation(change: change, initial: initial)..exchange = exchange;
  }

  @override
  GoalRecalculation createGoalRecalculation({
    required GoalAppData change,
    GoalAppData? initial,
  }) {
    return GoalRecalculation(change: change, initial: initial)..exchange = exchange;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('en_US');
  });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (methodCall) async => '/tmp/app-finance-test',
  );

  setUp(() {
    AppLocale.code = 'en';
    final preferences = _MockSharedPreferences();
    when(preferences.getString(AppPreferences.prefMonthStartDay)).thenReturn('');
    when(preferences.getString(AppPreferences.prefWeekStartDay)).thenReturn('1');
    when(preferences.getString(AppPreferences.prefCurrency)).thenReturn('USD');
    AppPreferences.pref = preferences;
  });

  test('_updateBill: both account and budget present trigger both collaborator paths', () {
    final exchange = _FakeExchange();

    final billSpy = _SpyBillRecalculation(
      change: BillAppData(title: 'seed', account: 'a', category: 'b'),
    );

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _NoopTransactionLogGateway(),
        collaboratorsFactory: _ConfigurableFactory(
          exchange: exchange,
          bill: billSpy,
        ),
      ),
    )..isLoading = true;

    appData.add(
      AccountAppData(
        uuid: 'acc-1',
        title: 'Account',
        type: 'cash',
      ),
      'acc-1',
    );
    appData.add(
      BudgetAppData(
        uuid: 'bud-1',
        title: 'Budget',
        amountLimit: 100,
      ),
      'bud-1',
    );

    appData.add(
      BillAppData(
        title: 'Bill',
        account: 'acc-1',
        category: 'bud-1',
        details: 20,
      ),
      'bill-1',
    );

    expect(billSpy.updateAccountCalls, 1);
    expect(billSpy.updateBudgetCalls, 1);
  });

  test('_updateBill: active store path (!isLoading) remains stable', () {
    final exchange = _FakeExchange();

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _PendingLoadTransactionLogGateway(),
        collaboratorsFactory: _ConfigurableFactory(exchange: exchange),
      ),
    )..isLoading = true;

    appData.add(
      AccountAppData(
        uuid: 'acc-1',
        title: 'Account',
        type: 'cash',
      ),
      'acc-1',
    );
    appData.add(
      BudgetAppData(
        uuid: 'bud-1',
        title: 'Budget',
        amountLimit: 100,
      ),
      'bud-1',
    );

    appData.isLoading = false;
    expect(
      () => appData.add(
        BillAppData(
          title: 'Bill',
          account: 'acc-1',
          category: 'bud-1',
          details: 20,
        ),
        'bill-live',
      ),
      returnsNormally,
    );
  });

  test('_updateBill: missing account skips account path and still updates budget path', () {
    final exchange = _FakeExchange();

    final billSpy = _SpyBillRecalculation(
      change: BillAppData(title: 'seed', account: 'x', category: 'y'),
    );

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _NoopTransactionLogGateway(),
        collaboratorsFactory: _ConfigurableFactory(
          exchange: exchange,
          bill: billSpy,
        ),
      ),
    )..isLoading = true;

    appData.add(
      BudgetAppData(
        uuid: 'bud-1',
        title: 'Budget',
        amountLimit: 100,
      ),
      'bud-1',
    );

    appData.add(
      BillAppData(
        title: 'Bill',
        account: 'acc-missing',
        category: 'bud-1',
        details: 20,
      ),
      'bill-2',
    );

    expect(billSpy.updateAccountCalls, 0);
    expect(billSpy.updateBudgetCalls, 1);
  });

  test('_updateBill: missing budget skips budget path and still updates account path', () {
    final exchange = _FakeExchange();

    final billSpy = _SpyBillRecalculation(
      change: BillAppData(title: 'seed', account: 'x', category: 'y'),
    );

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _NoopTransactionLogGateway(),
        collaboratorsFactory: _ConfigurableFactory(
          exchange: exchange,
          bill: billSpy,
        ),
      ),
    )..isLoading = true;

    appData.add(
      AccountAppData(
        uuid: 'acc-1',
        title: 'Account',
        type: 'cash',
      ),
      'acc-1',
    );

    appData.add(
      BillAppData(
        title: 'Bill',
        account: 'acc-1',
        category: 'bud-missing',
        details: 20,
      ),
      'bill-3',
    );

    expect(billSpy.updateAccountCalls, 1);
    expect(billSpy.updateBudgetCalls, 0);
  });

  test('_updateBill: edit path forwards previous account and budget references', () {
    final exchange = _FakeExchange();

    final billSpy = _SpyBillRecalculation(
      change: BillAppData(title: 'seed', account: 'x', category: 'y'),
    );

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _NoopTransactionLogGateway(),
        collaboratorsFactory: _ConfigurableFactory(
          exchange: exchange,
          bill: billSpy,
        ),
      ),
    )..isLoading = true;

    appData.add(
      AccountAppData(
        uuid: 'acc-old',
        title: 'Old account',
        type: 'cash',
      ),
      'acc-old',
    );
    appData.add(
      AccountAppData(
        uuid: 'acc-new',
        title: 'New account',
        type: 'cash',
      ),
      'acc-new',
    );
    appData.add(
      BudgetAppData(
        uuid: 'bud-old',
        title: 'Old budget',
        amountLimit: 100,
      ),
      'bud-old',
    );
    appData.add(
      BudgetAppData(
        uuid: 'bud-new',
        title: 'New budget',
        amountLimit: 100,
      ),
      'bud-new',
    );

    appData.add(
      BillAppData(
        title: 'Old bill',
        account: 'acc-old',
        category: 'bud-old',
        details: 5,
      ),
      'bill-edit',
    );
    appData.update(
      'bill-edit',
      BillAppData(
        uuid: 'bill-edit',
        title: 'New bill',
        account: 'acc-new',
        category: 'bud-new',
        details: 8,
      ),
    );

    expect(billSpy.lastAccountInitial?.uuid, 'acc-old');
    expect(billSpy.lastBudgetInitial?.uuid, 'bud-old');
  });

  test('_updateInvoice: accountFrom null performs only direct account update', () {
    final exchange = _FakeExchange();

    final invoiceSpy = _SpyInvoiceRecalculation(
      InvoiceAppData(title: 'seed', account: 'x'),
    );

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _NoopTransactionLogGateway(),
        collaboratorsFactory: _ConfigurableFactory(
          exchange: exchange,
          invoice: invoiceSpy,
        ),
      ),
    )..isLoading = true;

    appData.add(
      AccountAppData(
        uuid: 'acc-1',
        title: 'Target',
        type: 'cash',
      ),
      'acc-1',
    );

    appData.add(
      InvoiceAppData(
        title: 'Invoice',
        account: 'acc-1',
        details: 10,
      ),
      'inv-1',
    );

    expect(invoiceSpy.updateAccountCalls, 1);
    expect(invoiceSpy.reverseValues, [false]);
  });

  test('_updateInvoice: active store path (!isLoading) remains stable', () {
    final exchange = _FakeExchange();

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _PendingLoadTransactionLogGateway(),
        collaboratorsFactory: _ConfigurableFactory(exchange: exchange),
      ),
    )..isLoading = true;

    appData.add(
      AccountAppData(
        uuid: 'acc-1',
        title: 'Target',
        type: 'cash',
      ),
      'acc-1',
    );

    appData.isLoading = false;
    expect(
      () => appData.add(
        InvoiceAppData(
          title: 'Invoice',
          account: 'acc-1',
          details: 10,
        ),
        'inv-live',
      ),
      returnsNormally,
    );
  });

  test('_updateInvoice: accountFrom set performs both direct and reverse updates', () {
    final exchange = _FakeExchange();

    final invoiceSpy = _SpyInvoiceRecalculation(
      InvoiceAppData(title: 'seed', account: 'x'),
    );

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _NoopTransactionLogGateway(),
        collaboratorsFactory: _ConfigurableFactory(
          exchange: exchange,
          invoice: invoiceSpy,
        ),
      ),
    )..isLoading = true;

    appData.add(
      AccountAppData(
        uuid: 'acc-to',
        title: 'To',
        type: 'cash',
      ),
      'acc-to',
    );
    appData.add(
      AccountAppData(
        uuid: 'acc-from',
        title: 'From',
        type: 'cash',
      ),
      'acc-from',
    );

    appData.add(
      InvoiceAppData(
        title: 'Transfer',
        account: 'acc-to',
        accountFrom: 'acc-from',
        details: 20,
      ),
      'inv-2',
    );

    expect(invoiceSpy.updateAccountCalls, 2);
    expect(invoiceSpy.reverseValues, [false, true]);
  });

  test('_updateInvoice: missing current account skips recalculation calls', () {
    final exchange = _FakeExchange();

    final invoiceSpy = _SpyInvoiceRecalculation(
      InvoiceAppData(title: 'seed', account: 'x'),
    );

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _NoopTransactionLogGateway(),
        collaboratorsFactory: _ConfigurableFactory(
          exchange: exchange,
          invoice: invoiceSpy,
        ),
      ),
    )..isLoading = true;

    appData.add(
      InvoiceAppData(
        title: 'Invoice',
        account: 'acc-missing',
        details: 10,
      ),
      'inv-3',
    );

    expect(invoiceSpy.updateAccountCalls, 0);
  });

  test('_updateInvoice: edit path forwards previous account when initial exists', () {
    final exchange = _FakeExchange();

    final invoiceSpy = _SpyInvoiceRecalculation(
      InvoiceAppData(title: 'seed', account: 'x'),
    );

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _NoopTransactionLogGateway(),
        collaboratorsFactory: _ConfigurableFactory(
          exchange: exchange,
          invoice: invoiceSpy,
        ),
      ),
    )..isLoading = true;

    appData.add(
      AccountAppData(
        uuid: 'acc-old',
        title: 'Old',
        type: 'cash',
      ),
      'acc-old',
    );
    appData.add(
      AccountAppData(
        uuid: 'acc-new',
        title: 'New',
        type: 'cash',
      ),
      'acc-new',
    );

    appData.add(
      InvoiceAppData(
        title: 'Old invoice',
        account: 'acc-old',
        details: 10,
      ),
      'inv-edit',
    );
    appData.update(
      'inv-edit',
      InvoiceAppData(
        uuid: 'inv-edit',
        title: 'New invoice',
        account: 'acc-new',
        details: 20,
      ),
    );

    expect(invoiceSpy.updateAccountCalls, 2);
    expect(invoiceSpy.accountInitials.last?.uuid, 'acc-old');
  });

  test('_updateBill: collaborator factory failure is propagated', () {
    final exchange = _FakeExchange();

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _NoopTransactionLogGateway(),
        collaboratorsFactory: _FactoryCrashOnBill(exchange: exchange),
      ),
    )..isLoading = true;

    appData.add(
      AccountAppData(
        uuid: 'acc-1',
        title: 'A',
        type: 'cash',
      ),
      'acc-1',
    );

    expect(
      () => appData.add(
        BillAppData(
          title: 'Bill',
          account: 'acc-1',
          category: 'bud-missing',
          details: 12,
        ),
        'bill-crash',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('_updateInvoice: collaborator factory failure is propagated', () {
    final exchange = _FakeExchange();

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _NoopTransactionLogGateway(),
        collaboratorsFactory: _FactoryCrashOnInvoice(exchange: exchange),
      ),
    )..isLoading = true;

    appData.add(
      AccountAppData(
        uuid: 'acc-1',
        title: 'A',
        type: 'cash',
      ),
      'acc-1',
    );

    expect(
      () => appData.add(
        InvoiceAppData(
          title: 'Invoice',
          account: 'acc-1',
          details: 10,
        ),
        'inv-crash',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('_stream: catches transaction-log add exceptions', () async {
    final exchange = _FakeExchange();

    final appSync = _CapturingAppSync();

    AppData(
      appSync,
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: _ThrowingTransactionLogGateway(),
        collaboratorsFactory: _ConfigurableFactory(exchange: exchange),
      ),
    );

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(appSync.callback, isNotNull);
    expect(() => appSync.callback!.call('line-data'), returnsNormally);
  });
}
