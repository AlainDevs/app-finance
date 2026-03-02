// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

// ignore_for_file: type=lint

import 'package:app_finance/_classes/math/bill_recalculation.dart';
import 'package:app_finance/_classes/math/budget_prediction.dart';
import 'package:app_finance/_classes/math/budget_recalculation.dart';
import 'package:app_finance/_classes/math/goal_recalculation.dart';
import 'package:app_finance/_classes/math/invoice_recalculation.dart';
import 'package:app_finance/_classes/math/total_recalculation.dart';
import 'package:app_finance/_classes/storage/app_data_store.dart';
import 'package:app_finance/_classes/storage/transaction_log.dart';
import 'package:app_finance/_classes/structure/bill_app_data.dart';
import 'package:app_finance/_classes/structure/budget_app_data.dart';
import 'package:app_finance/_classes/structure/currency/exchange.dart';
import 'package:app_finance/_classes/structure/goal_app_data.dart';
import 'package:app_finance/_classes/structure/invoice_app_data.dart';

abstract class AppDataTransactionLogGateway {
  Future<bool> load(AppDataStore store);

  bool add(
    AppDataStore store,
    String line,
    bool isEncrypted, [
    bool onlyNew = false,
  ]);

  void save(dynamic content);
}

class TransactionLogGateway implements AppDataTransactionLogGateway {
  const TransactionLogGateway();

  @override
  Future<bool> load(AppDataStore store) => TransactionLog.load(store);

  @override
  bool add(
    AppDataStore store,
    String line,
    bool isEncrypted, [
    bool onlyNew = false,
  ]) =>
      TransactionLog.add(store, line, isEncrypted, onlyNew);

  @override
  void save(dynamic content) => TransactionLog.save(content);
}

abstract class AppDataCollaboratorsFactory {
  Exchange createExchange(AppDataStore store);

  TotalRecalculation createTotalRecalculation(Exchange exchange);

  InvoiceRecalculation createInvoiceRecalculation(
    InvoiceAppData change, [
    InvoiceAppData? initial,
  ]);

  BillRecalculation createBillRecalculation({
    required BillAppData change,
    BillAppData? initial,
  });

  BudgetRecalculation createBudgetRecalculation({
    required BudgetAppData change,
    BudgetAppData? initial,
  });

  GoalRecalculation createGoalRecalculation({
    required GoalAppData change,
    GoalAppData? initial,
  });
}

class DefaultAppDataCollaboratorsFactory implements AppDataCollaboratorsFactory {
  const DefaultAppDataCollaboratorsFactory();

  @override
  Exchange createExchange(AppDataStore store) => Exchange(store: store.exchangeStore);

  @override
  TotalRecalculation createTotalRecalculation(Exchange exchange) {
    return TotalRecalculation(exchange: exchange);
  }

  @override
  InvoiceRecalculation createInvoiceRecalculation(
    InvoiceAppData change, [
    InvoiceAppData? initial,
  ]) {
    return InvoiceRecalculation(change, initial);
  }

  @override
  BillRecalculation createBillRecalculation({
    required BillAppData change,
    BillAppData? initial,
  }) {
    return BillRecalculation(change: change, initial: initial);
  }

  @override
  BudgetRecalculation createBudgetRecalculation({
    required BudgetAppData change,
    BudgetAppData? initial,
  }) {
    return BudgetRecalculation(change: change, initial: initial);
  }

  @override
  GoalRecalculation createGoalRecalculation({
    required GoalAppData change,
    GoalAppData? initial,
  }) {
    return GoalRecalculation(change: change, initial: initial);
  }
}

class AppDataDependencies {
  final BudgetPrediction prediction;
  final AppDataTransactionLogGateway transactionLog;
  final AppDataCollaboratorsFactory collaboratorsFactory;

  const AppDataDependencies({
    required this.prediction,
    required this.transactionLog,
    required this.collaboratorsFactory,
  });
}
