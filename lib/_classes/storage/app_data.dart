// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

// ignore_for_file: type=lint

export 'package:app_finance/_classes/storage/app_data_type.dart';

import 'dart:collection';
import 'package:app_finance/_classes/controller/iterator_controller.dart';
import 'package:app_finance/_classes/herald/app_start_of_month.dart';
import 'package:app_finance/_classes/herald/app_sync.dart';
import 'package:app_finance/_classes/math/budget_prediction.dart';
import 'package:app_finance/_classes/storage/history_data.dart';
import 'package:app_finance/_classes/storage/app_data_store.dart';
import 'package:app_finance/_classes/storage/di/app_data_dependencies.dart';
import 'package:app_finance/_classes/storage/app_data_type.dart';
import 'package:app_finance/_classes/structure/account_app_data.dart';
import 'package:app_finance/_classes/structure/bill_app_data.dart';
import 'package:app_finance/_classes/structure/budget_app_data.dart';
import 'package:app_finance/_classes/structure/currency_app_data.dart';
import 'package:app_finance/_classes/structure/goal_app_data.dart';
import 'package:app_finance/_classes/structure/interface_app_data.dart';
import 'package:app_finance/_classes/structure/invoice_app_data.dart';
import 'package:app_finance/_classes/structure/payment_app_data.dart';
import 'package:app_finance/_classes/structure/summary_app_data.dart';
import 'package:app_finance/_ext/iterable_ext.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

typedef AppDataGetter = ({
  List<dynamic> list,
  double total,
  InterfaceIterator stream,
});

class AppData extends ChangeNotifier implements AppDataStore, AppDataExchangeStore {
  final AppSync appSync;
  final AppDataDependencies _dependencies;
  bool isLoading = false;
  final _hashTable = HashMap<String, dynamic>();
  final _data = <AppDataType, SummaryAppData>{};
  BudgetPrediction get prediction => _dependencies.prediction;

  @override
  AppDataExchangeStore get exchangeStore => this;

  AppData(
    this.appSync, {
    required AppDataDependencies dependencies,
  })  : _dependencies = dependencies,
        super() {
    isLoading = true;
    int startingDay = AppStartOfMonth.get();
    for (var key in AppDataType.values) {
      _data[key] = SummaryAppData(startingDay: startingDay);
    }
    _dependencies.collaboratorsFactory.createExchange(this).getDefaultCurrency();
    _dependencies.transactionLog
        .load(this)
        .then((_) async => await restate())
        .then((_) => appSync.follow(AppData, _stream));
  }

  @override
  dispose() {
    super.dispose();
    appSync.unfollow(AppData);
  }

  void _stream(String value) {
    try {
      _dependencies.transactionLog.add(this, value, true, true);
    } catch (e) {
      //...
    }
  }

  Future<void> flush() async {
    isLoading = true;
    int startingDay = AppStartOfMonth.get();
    _hashTable.clear();
    _data.updateAll((key, value) => SummaryAppData(startingDay: startingDay));
    await _dependencies.transactionLog.load(this);
    await restate();
  }

  Future<void> restate() async {
    await updateTotals(AppDataType.values);
    isLoading = false;
    notifyListeners();
  }

  void _set(AppDataType property, dynamic value) {
    _hashTable[value.uuid] = value;
    _data[property]?.add(value.uuid, updatedAt: value.createdAt);
    if (!isLoading) {
      _dependencies.transactionLog.save(value);
      appSync.send(value.toStream());
    }
    _notify();
  }

  void _notify([_]) {
    if (!isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  @override
  dynamic add(InterfaceAppData value, [String? uuid]) {
    value.uuid = uuid ?? const Uuid().v4();
    _update(null, value);

    return getByUuid(value.uuid!);
  }

  @override
  void update(String uuid, InterfaceAppData value, [bool createIfMissing = false]) {
    var initial = getByUuid(uuid, false);
    if (initial != null || createIfMissing) {
      _update(initial, value);
    }
  }

  Future<void> updateTotals(List<AppDataType> scope) async {
    final accountTotal = getTotal(AppDataType.accounts);
    final exchange = _dependencies.collaboratorsFactory.createExchange(this);
    final rec = _dependencies.collaboratorsFactory.createTotalRecalculation(exchange);
    for (AppDataType type in scope) {
      await rec.updateTotal(type, _data[type], _hashTable);
    }
    if (scope.contains(AppDataType.accounts)) {
      rec.updateGoals(getList(AppDataType.goals, false), accountTotal, getTotal(AppDataType.accounts));
    }
  }

  void _update(InterfaceAppData? initial, InterfaceAppData change) {
    if (change.getType() != AppDataType.budgets && change.getType() != AppDataType.payments) {
      HistoryData.addLog(change.uuid, change, initial?.details ?? 0.0, change.details);
    }
    switch (change.getType()) {
      case AppDataType.accounts:
        _updateAccount(initial as AccountAppData?, change as AccountAppData);
        break;
      case AppDataType.bills:
        (change as BillAppData).setState(this);
        _updateBill(initial as BillAppData?, change);
        break;
      case AppDataType.budgets:
        (change as BudgetAppData).setState(this);
        _updateBudget(initial as BudgetAppData?, change);
        HistoryData.addLog(change.uuid, change, initial?.amountLimit ?? 0.0, change.amountLimit);
        break;
      case AppDataType.goals:
        _updateGoal(initial as GoalAppData?, change as GoalAppData);
        break;
      case AppDataType.currencies:
        _updateCurrency(initial as CurrencyAppData?, change as CurrencyAppData);
        break;
      case AppDataType.invoice:
        (change as InvoiceAppData).setState(this);
        _updateInvoice(initial as InvoiceAppData?, change);
        break;
      case AppDataType.payments:
        _updatePayment(initial as PaymentAppData?, change as PaymentAppData);
        break;
    }
  }

  void _updateInvoice(InvoiceAppData? initial, InvoiceAppData change) {
    _set(AppDataType.invoice, change);
    AccountAppData? currAccount = getByUuid(change.account, false);
    AccountAppData? prevAccount;
    if (initial != null) {
      prevAccount = getByUuid(initial.account, false);
      if (prevAccount != null) {
        _data[AppDataType.accounts]?.add(initial.account);
      }
    }
    if (currAccount != null) {
      final rec = _dependencies.collaboratorsFactory.createInvoiceRecalculation(change, initial)
        ..exchange = _dependencies.collaboratorsFactory.createExchange(this);
      rec.updateAccount(currAccount, prevAccount);
      _data[AppDataType.accounts]?.add(change.account);
      if (change.accountFrom != null) {
        rec.updateAccount(getByUuid(change.accountFrom!, false),
            initial != null && initial.accountFrom != null ? getByUuid(initial.accountFrom!, false) : null, true);
        _data[AppDataType.accounts]?.add(change.accountFrom!);
      }
    }
    if (!isLoading) {
      updateTotals([AppDataType.accounts]).then(_notify);
    }
  }

  void _updateAccount(AccountAppData? initial, AccountAppData change) {
    _set(AppDataType.accounts, change);
    if (!isLoading) {
      updateTotals([AppDataType.accounts]).then(_notify);
    }
  }

  void _updateBill(BillAppData? initial, BillAppData change) {
    AccountAppData? currAccount = getByUuid(change.account, false);
    AccountAppData? prevAccount;
    BudgetAppData? currBudget = getByUuid(change.category, false);
    BudgetAppData? prevBudget;
    final exchange = _dependencies.collaboratorsFactory.createExchange(this);
    change.exchangeAccount = exchange.reform(1.0, change.currency, currAccount?.currency);
    change.exchangeCategory = exchange.reform(1.0, change.currency, currBudget?.currency);
    if (initial != null) {
      prevAccount = getByUuid(initial.account, false);
      if (prevAccount != null) {
        _data[AppDataType.accounts]?.add(initial.account);
      }
      prevBudget = getByUuid(initial.category, false);
      if (prevBudget != null) {
        _data[AppDataType.budgets]?.add(initial.category);
      }
    }
    prediction.add(change);
    final rec = _dependencies.collaboratorsFactory.createBillRecalculation(change: change, initial: initial)
      ..exchange = exchange;
    if (currAccount != null) {
      rec.updateAccount(currAccount, prevAccount);
      _data[AppDataType.accounts]?.add(change.account);
    }
    if (currBudget != null) {
      rec.updateBudget(currBudget, prevBudget);
      _data[AppDataType.budgets]?.add(change.category);
    }
    _set(AppDataType.bills, change);
    if (!isLoading) {
      updateTotals([AppDataType.bills, AppDataType.accounts, AppDataType.budgets]).then(_notify);
    }
  }

  void _updateBudget(BudgetAppData? initial, BudgetAppData change) {
    _dependencies.collaboratorsFactory.createBudgetRecalculation(change: change, initial: initial)
      ..exchange = _dependencies.collaboratorsFactory.createExchange(this)
      ..updateBudget();
    _set(AppDataType.budgets, change);
    if (!isLoading) {
      updateTotals([AppDataType.budgets]).then(_notify);
    }
  }

  void _updateGoal(GoalAppData? initial, GoalAppData change) {
    _dependencies.collaboratorsFactory.createGoalRecalculation(change: change, initial: initial)
      ..exchange = _dependencies.collaboratorsFactory.createExchange(this)
      ..updateGoal();
    _set(AppDataType.goals, change);
    if (!isLoading) {
      updateTotals([AppDataType.goals]).then(_notify);
    }
  }

  void _updateCurrency(CurrencyAppData? initial, CurrencyAppData change) {
    _set(AppDataType.currencies, change);
    if (!isLoading) {
      updateTotals(AppDataType.values).then(_notify);
    }
  }

  void _updatePayment(PaymentAppData? initial, PaymentAppData change) {
    _set(AppDataType.payments, change);
  }

  AppDataGetter get(AppDataType property) {
    return (
      list: getList(property),
      total: getTotal(property),
      stream: getStream<InterfaceAppData>(property),
    );
  }

  @override
  List<dynamic> getList(AppDataType property, [bool isClone = true]) {
    return (_data[property]?.list ?? [])
        .map((uuid) => getByUuid(uuid, isClone))
        .where((element) => !element.hidden)
        .toList();
  }

  @override
  InterfaceIterator getStream<M extends InterfaceAppData>(AppDataType property,
      {bool inverse = true, double? boundary, Function? filter}) {
    if (_data[property] == null) {
      return IteratorController<num, dynamic, M>(SplayTreeMap<num, dynamic>(), transform: getByUuid);
    }

    return _data[property]!.origin.toStream<M>(
          inverse,
          transform: getByUuid,
          boundary: boundary,
          filter: (M v) => v.hidden || filter?.call(v) == true,
        );
  }

  @override
  List<dynamic> getActualList(AppDataType property, [bool isClone = true]) {
    return (_data[property]?.listActual ?? [])
        .map((uuid) => getByUuid(uuid, isClone))
        .where((element) => !element.hidden)
        .toList();
  }

  @override
  double getTotal(AppDataType property) {
    return _data[property]?.total ?? 0.0;
  }

  @override
  dynamic getByUuid(String uuid, [bool isClone = true]) {
    if (uuid == '') return null;

    var obj = isClone ? _hashTable[uuid]?.clone() : _hashTable[uuid];
    if (obj is BillAppData || obj is BudgetAppData || obj is InvoiceAppData) {
      obj.setState(this);
    }

    return obj;
  }
}
