// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gherkin_wrapper/flutter_gherkin_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages, because of the gherkin package
import 'package:gherkin/gherkin.dart';

import 'package:app_finance/_configs/test_keys.dart';

import '../../../screen_capture.dart';

class EnterTextField extends When2WithWorld<String, String, World> {
  @override
  RegExp get pattern => RegExp(r"I enter {string} to {string} text field");

  @override
  Future<void> executeStep(String value, String tooltip) async {
    ScreenCapture.seize(runtimeType.toString());
    Finder field = _finderForTooltip(tooltip);
    if (field.evaluate().isEmpty) {
      field = find.byKey(TestKeys.listSelectorSearchInput);
    }
    if (field.evaluate().isEmpty) {
      field = find.bySemanticsLabel(RegExp(tooltip));
      // Cover SearchAnchor inputs
      if (field.evaluate().isEmpty) {
        field = find.byWidgetPredicate((widget) {
          return widget is TextField &&
              (widget.decoration?.hintText == tooltip || widget.decoration?.labelText == tooltip);
        });
      }
    }
    expectSync(field, findsOneWidget);
    await FileRunner.tester.ensureVisible(field);
    await FileRunner.tester.tap(field, warnIfMissed: false);
    await FileRunner.tester.pump();
    await FileRunner.tester.enterText(field, value);
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

  Finder _finderForTooltip(String tooltip) {
    switch (tooltip) {
      case 'Enter Account Identifier':
        return find.byKey(TestKeys.accountTitleInput);
      case 'Set Balance':
        final accountBalanceField = find.byKey(TestKeys.accountBalanceInput);
        if (accountBalanceField.evaluate().isNotEmpty) {
          return accountBalanceField;
        }
        final budgetBalanceField = find.byKey(TestKeys.budgetBalanceInput);
        if (budgetBalanceField.evaluate().isNotEmpty) {
          return budgetBalanceField;
        }

        return find.byKey(const ValueKey('unmapped.tooltip'));
      case 'Set Amount':
        return find.byKey(TestKeys.billAmountInput);
      case 'Set Expense Details':
        return find.byKey(TestKeys.billDescriptionInput);
      case 'Enter Budget Category Name':
        return find.byKey(TestKeys.budgetTitleInput);
      default:
        return find.byKey(const ValueKey('unmapped.tooltip'));
    }
  }
}
