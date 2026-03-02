// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

// ignore_for_file: type=lint

import 'dart:async';

import 'package:app_finance/_classes/herald/app_sync.dart';
import 'package:app_finance/_classes/math/budget_prediction.dart';
import 'package:app_finance/_classes/storage/app_data.dart';
import 'package:app_finance/_classes/storage/app_data_store.dart';
import 'package:app_finance/_classes/storage/app_preferences.dart';
import 'package:app_finance/_classes/storage/di/app_data_dependencies.dart';
import 'package:app_finance/_classes/structure/currency/exchange.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAppSync extends Mock implements AppSync {}

class _MockSharedPreferences extends Mock implements SharedPreferences {}

class _MockExchange extends Mock implements Exchange {}

class _MockTransactionLogGateway extends Mock implements AppDataTransactionLogGateway {
  _MockTransactionLogGateway(this._loadResult);

  final Future<bool> _loadResult;

  @override
  Future<bool> load(AppDataStore store) => super.noSuchMethod(
        Invocation.method(#load, [store]),
        returnValue: _loadResult,
        returnValueForMissingStub: _loadResult,
      ) as Future<bool>;
}

class _MockCollaboratorsFactory extends Mock implements AppDataCollaboratorsFactory {
  _MockCollaboratorsFactory(this._exchange);

  final Exchange _exchange;

  @override
  Exchange createExchange(AppDataStore store) => super.noSuchMethod(
        Invocation.method(#createExchange, [store]),
        returnValue: _exchange,
        returnValueForMissingStub: _exchange,
      ) as Exchange;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppData uses injected DI collaborators during initialization', () {
    final preferences = _MockSharedPreferences();
    when(preferences.getString(AppPreferences.prefMonthStartDay)).thenReturn(null);
    AppPreferences.pref = preferences;

    final exchange = _MockExchange();
    when(exchange.getDefaultCurrency()).thenReturn(null);

    final loadCompleter = Completer<bool>();
    final transactionLog = _MockTransactionLogGateway(loadCompleter.future);
    final collaboratorsFactory = _MockCollaboratorsFactory(exchange);

    final appData = AppData(
      _MockAppSync(),
      dependencies: AppDataDependencies(
        prediction: BudgetPrediction(),
        transactionLog: transactionLog,
        collaboratorsFactory: collaboratorsFactory,
      ),
    );

    verify(collaboratorsFactory.createExchange(appData)).called(1);
    verify(exchange.getDefaultCurrency()).called(1);
    verify(transactionLog.load(appData)).called(1);

    verifyNoMoreInteractions(collaboratorsFactory);
    verifyNoMoreInteractions(exchange);
    verifyNoMoreInteractions(transactionLog);
  });
}
