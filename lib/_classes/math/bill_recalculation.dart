// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:app_finance/_classes/math/abstract_recalculation.dart';
import 'package:app_finance/_classes/storage/history_data.dart';
import 'package:app_finance/_classes/structure/abstract_app_data.dart';
import 'package:app_finance/_classes/structure/account_app_data.dart';
import 'package:app_finance/_classes/structure/bill_app_data.dart';
import 'package:app_finance/_classes/structure/budget_app_data.dart';

class BillRecalculation extends AbstractRecalculation {
  BillAppData change;
  BillAppData? initial;

  BillRecalculation({
    required this.change,
    this.initial,
  });

  @override
  double getDelta() => throw UnimplementedError();

  double getPrevDelta() => initial?.hidden == true ? 0.0 : initial?.details;

  double getStateDelta(AbstractAppData? prev, AbstractAppData? curr, [bool isBudget = true]) {
    final initialDetails = (initial?.details ?? 0.0) * _getInitialExchangeRate(isBudget);
    final delta = _getCurrentDelta(isBudget);
    if (!_isSameStateEntity(prev, curr)) {
      return delta;
    }

    if (initial?.hidden == true) {
      return delta;
    }

    return delta - initialDetails;
  }

  BillRecalculation updateAccount(AccountAppData accountChange, AccountAppData? accountInitial) {
    double? diffDelta;
    final initialBill = initial;
    if (accountInitial != null && initialBill != null && accountChange.uuid != accountInitial.uuid) {
      diffDelta = getPrevDelta();
      HistoryData.addLog(accountInitial.uuid ?? '', initialBill, 0.0, diffDelta, initialBill.uuid);
    }
    double delta = getStateDelta(accountInitial, accountChange, false);
    HistoryData.addLog(accountChange.uuid ?? '', change, 0.0, -delta, change.uuid);
    if (diffDelta != null && accountInitial?.createdAt.isBefore(initialBill?.createdAt ?? DateTime.now()) == true) {
      accountInitial?.details += exchange.reform(diffDelta, initialBill?.currency, accountInitial.currency);
    }
    if (accountChange.createdAt.isBefore(change.createdAt)) {
      accountChange.details -= delta;
    }

    return this;
  }

  BillRecalculation updateBudget(BudgetAppData budgetChange, BudgetAppData? budgetInitial) {
    if (budgetInitial != null &&
        budgetChange.uuid != budgetInitial.uuid &&
        !budgetInitial.getDateBoundary().isAfter(change.createdAt)) {
      double prevDelta = exchange.reform(getPrevDelta(), initial?.currency, budgetInitial.currency);
      budgetInitial.progress = getProgress(budgetInitial.amountLimit, budgetInitial.progress, -prevDelta);
      budgetInitial.amount -= prevDelta;
    }
    if (!budgetChange.getDateBoundary().isAfter(change.createdAt)) {
      double delta = getStateDelta(budgetInitial, budgetChange, true);
      budgetChange.progress = getProgress(budgetChange.amountLimit, budgetChange.progress, delta);
      budgetChange.amount += delta;
    }

    return this;
  }

  double _getCurrentDelta(bool isBudget) {
    final baseDelta = change.hidden ? 0.0 : change.details;

    return baseDelta * _getChangeExchangeRate(isBudget);
  }

  double _getChangeExchangeRate(bool isBudget) {
    return isBudget ? change.exchangeCategory : change.exchangeAccount;
  }

  double _getInitialExchangeRate(bool isBudget) {
    return isBudget ? initial?.exchangeCategory ?? 1.0 : initial?.exchangeAccount ?? 1.0;
  }

  bool _isSameStateEntity(AbstractAppData? prev, AbstractAppData? curr) {
    return initial != null && prev?.uuid == curr?.uuid;
  }
}
