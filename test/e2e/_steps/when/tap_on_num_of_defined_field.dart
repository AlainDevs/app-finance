// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:app_finance/design/form/currency_selector.dart';
import 'package:app_finance/design/form/currency_selector_code.dart';
import 'package:app_finance/design/generic/base_line_widget.dart';
import 'package:app_finance/_configs/test_keys.dart';
import 'package:flutter_gherkin_wrapper/flutter_gherkin_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages, because of the gherkin package
import 'package:gherkin/gherkin.dart';

import '../../../screen_capture.dart';

class TapOnNumOfDefinedField extends When2WithWorld<int, String, World> {
  @override
  RegExp get pattern => RegExp(r"I tap on {int} index of {string} fields");

  @override
  Future<void> executeStep(int order, String type) async {
    ScreenCapture.seize(runtimeType.toString());
    Finder list = switch (type) {
      'ListSelector' => find.byKey(TestKeys.accountTypeSelector),
      'ListAccountSelector' => find.byKey(TestKeys.billAccountSelector),
      'ListBudgetSelector' => find.byKey(TestKeys.billBudgetSelector),
      'BaseLineWidget' => find.byType(BaseLineWidget),
      'CurrencySelector' => find.byType(BaseCurrencySelector),
      'CodeCurrencySelector' => find.byType(CodeCurrencySelector),
      'AccountSelector' => find.byKey(TestKeys.billAccountSelector),
      'BudgetSelector' => find.byKey(TestKeys.billBudgetSelector),
      _ => throw Exception('Not defined'),
    };
    final target = order == 0 ? list : list.at(order);
    expectSync(target, findsOneWidget);
    await FileRunner.tester.ensureVisible(target);
    await FileRunner.tester.tap(target, warnIfMissed: false);
    await _safePumpAndSettle();
    ScreenCapture.seize(runtimeType.toString());
  }

  Future<void> _safePumpAndSettle() async {
    try {
      await FileRunner.tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 2),
      );
    } catch (_) {
      await FileRunner.tester.pump(const Duration(milliseconds: 100));
    }
  }
}
