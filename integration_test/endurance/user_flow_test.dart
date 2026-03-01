// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

// ignore_for_file: missing-test-assertion, prefer-moving-to-variable, no-magic-number, double-literal-format

import 'dart:io';
import 'dart:math';

import 'package:app_finance/_classes/storage/app_preferences.dart';
import 'package:flutter_gherkin_wrapper/flutter_gherkin_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/e2e/e2e_test.list.dart';
import '../../test/e2e/_steps/given/first_run.dart';
import '../../test/pump_main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  ExecutableStepIterator.inject(classList);

  Future<void> cleanUp() async {
    AppPreferences.pref = await SharedPreferences.getInstance();
    await AppPreferences.pref.clear();
    final path = await getApplicationDocumentsDirectory();
    var file = File('${path.absolute.path}/.terCAD/app-finance.log');
    if (!file.existsSync()) {
      file = File('${Directory.systemTemp.absolute.path}/.terCAD/app-finance.log');
    }
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<void> run(WidgetTester tester, String scenario) async {
    final reporter = FileReporter();
    final step = await FileReader().getFromString(scenario, reporter);
    final runner = FileRunner(tester, reporter);
    final result = await runner.run(step);
    if (!result) {
      reporter.publish();
    }
    expectSync(result, true);
  }

  Future<void> firstRun(WidgetTester tester) async {
    FileRunner.tester = tester;
    await FirstRun().executeStep();
    expect(find.text('Initial Setup'), findsOneWidget);
  }

  Future<void> createAccount(WidgetTester tester, int counter) async {
    await run(tester, '''
      @start
      Feature: Account
        Scenario: Create new Account
          Given Opened Account Form
          When I tap on 0 index of "ListSelector" fields
          And I tap "Bank Account" element
          And I enter "Account #$counter" to "Enter Account Identifier" text field
          And I enter "10000" to "Set Balance" text field
          And I tap "Create new Account" button
      ''');
  }

  Future<void> createBudget(WidgetTester tester, int counter) async {
    await run(tester, '''
      @start
      Feature: Budget
        Scenario: Create new Budget
          Given Opened Budget Form
          When I enter "Budget #$counter" to "Enter Budget Category Name" text field
          And I enter "1000" to "Set Balance" text field
          And I tap "Create new Budget Category" button
      ''');
  }

  Future<void> createBill(WidgetTester tester, int counter) async {
    await run(tester, '''
      @start
      Feature: Bill
        Scenario: Create new Bill
          Given I am on "Home" page
          When I tap "Add Bill , Income or Transfer" button
          And I tap on 0 index of "ListAccountSelector" fields
          And I tap on 0 index of "BaseLineWidget" fields
          And I tap on 0 index of "ListBudgetSelector" fields
          And I tap on 0 index of "BaseLineWidget" fields
          And I enter "10" to "Set Amount" text field
          And I enter "Bill #$counter" to "Set Expense Details" text field
          And I tap "Add new Bill" button
      ''');
  }

  testWidgets('Imitate User Activities', (WidgetTester tester) async {
    final startTime = DateTime.now();
    await cleanUp();
    await PumpMain.init(tester, true);
    await firstRun(tester);
    var duration = Duration.zero;
    int idx = 0;
    final random = Random();
    while (duration.inMinutes < 0) {
      if (random.nextDouble() <= 0.05) await createAccount(tester, idx);
      await FileRunner.tester.pumpAndSettle(const Duration(seconds: 5));
      if (random.nextDouble() <= 0.10) await createBudget(tester, idx);
      await FileRunner.tester.pumpAndSettle(const Duration(seconds: 5));
      if (random.nextDouble() <= 0.90) await createBill(tester, idx);
      await FileRunner.tester.pumpAndSettle(const Duration(seconds: 5));
      final endTime = DateTime.now();
      duration = endTime.difference(startTime);
      idx++;
    }
  }, timeout: const Timeout(Duration(hours: 9)));
}
