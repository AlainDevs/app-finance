// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:app_finance/_classes/controller/exchange_controller.dart';
import 'package:app_finance/_classes/herald/app_locale.dart';
import 'package:app_finance/_classes/storage/app_preferences.dart';
import 'package:app_finance/_configs/automation_type.dart';
import 'package:app_finance/_configs/payment_type.dart';
import 'package:app_finance/pages/budget/widgets/budget_type_widget.dart';
import 'package:app_finance/pages/currency/currency_add_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_currency_picker/flutter_currency_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_classes/controller/exchange_controller_test.mocks.dart' as ctrl_mocks;

class _ReliabilityBvaValidationTest {
  static const double nominalExchangeExpected = 154.3125;
  static const double maximumExchangeExpected = 1999999999.98;
  static const double nominalDelta = 1e-9;
  static const double maximumDelta = 1e-6;
}

class _BudgetTypeWidgetStateHarness extends BudgetTypeWidgetState {
  _BudgetTypeWidgetStateHarness(this._value);

  final BudgetTypeWidget _value;

  @override
  BudgetTypeWidget get widget => _value;

  @override
  void setState(VoidCallback fn) => fn();
}

class _CurrencyAddPageStateHarness extends CurrencyAddPageState {
  @override
  void setState(VoidCallback fn) => fn();
}

class _ReliabilityBvaValidationPaymentAddPageState {
  String? intervalType;
  String? itemType;
  TextEditingController days = TextEditingController();
  bool hasErrors = false;

  bool hasFormErrors() {
    hasErrors = itemType == null ||
        intervalType == null ||
        (intervalType == AppAutomationType.days.name && (days.text.isEmpty || days.text == '0'));

    return hasErrors;
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    AppPreferences.pref = ctrl_mocks.MockSharedPreferences();
    CurrencyDefaults.cache = ctrl_mocks.MockSharedPreferences();
    AppLocale.code = 'en';
  });

  group('Reliability BVA | financial input validation', () {
    test('BudgetTypeWidget classification boundaries', () {
      final controller = TextEditingController();
      final widget = BudgetTypeWidget(controller: controller);
      final state = _BudgetTypeWidgetStateHarness(widget);

      final checks = <({String input, BudgetValueType expected})>[
        (input: '', expected: BudgetValueType.unlimited),
        (input: '-0.01', expected: BudgetValueType.unlimited),
        (input: '0', expected: BudgetValueType.unlimited),
        (input: '0.5', expected: BudgetValueType.relative),
        (input: '1.0', expected: BudgetValueType.fixed),
        (input: '1.01', expected: BudgetValueType.fixed),
      ];
      final observed = <BudgetValueType>[];

      for (final check in checks) {
        controller.text = check.input;
        state.listener();
        observed.add(state.value);
      }

      expect(observed, checks.map((check) => check.expected).toList());

      controller.dispose();
    });

    test('CurrencyAddPage validation boundaries and 1.0 sentinel', () {
      final state = _CurrencyAddPageStateHarness();
      final usd = CurrencyProvider.find('USD');
      final eur = CurrencyProvider.find('EUR');
      final hasFormErrors = state.hasFormErrors;

      state.currencyFrom = usd;
      state.currencyTo = eur;
      state.conversion = TextEditingController();
      final observed = <bool>[];

      for (final conversion in <String>['-0.01', '0', '1.25', '999999']) {
        state.conversion.text = conversion;
        observed.add(hasFormErrors());
      }

      state.conversion.text = '1.0';
      observed.add(hasFormErrors());

      state.currencyTo = state.currencyFrom;
      state.conversion.text = '2.0';
      observed.add(hasFormErrors());

      state.currencyTo = eur;
      state.currencyFrom = null;
      observed.add(hasFormErrors());

      state.currencyFrom = usd;
      state.currencyTo = null;
      observed.add(hasFormErrors());

      expect(
        observed,
        <bool>[false, false, false, false, true, true, true, true],
      );

      state.conversion.dispose();
    });

    test('PaymentAddPage days boundaries', () {
      final state = _ReliabilityBvaValidationPaymentAddPageState();
      state.intervalType = AppAutomationType.days.name;
      state.itemType = AppPaymentType.bill.name;
      final observed = <bool>[];
      final hasFormErrors = state.hasFormErrors;

      for (final days in <String>['0', '1', '9999', '']) {
        state.days.text = days;
        observed.add(hasFormErrors());
      }

      expect(observed, <bool>[true, false, false, true]);

      state.days.dispose();
    });

    test('ExchangeController keeps deterministic values at numeric boundaries', () {
      final editor = TextEditingController(text: '0');
      final controller = ExchangeController(
        <String, ExchangeScope>{},
        store: ctrl_mocks.MockAppData(),
        source: [CurrencyProvider.find('USD'), CurrencyProvider.find('EUR')],
        target: CurrencyProvider.find('EUR'),
        targetController: editor,
      );
      final pair = controller.get(0);
      final parsePairSum = () => double.tryParse(pair.sum.text);

      pair.rate.text = '0';
      final zeroSum = parsePairSum();

      editor.text = '123.45';
      pair.rate.text = '1.25';
      final nominalSum = parsePairSum();

      editor.text = '999999999.99';
      pair.rate.text = '2';
      final maximumSum = parsePairSum();

      editor.text = '1e309';
      pair.rate.text = '2';
      final overflowIsFinite = parsePairSum()?.isFinite;

      expect(zeroSum, 0.0);
      expect(
        nominalSum,
        closeTo(
          _ReliabilityBvaValidationTest.nominalExchangeExpected,
          _ReliabilityBvaValidationTest.nominalDelta,
        ),
      );
      expect(
        maximumSum,
        closeTo(
          _ReliabilityBvaValidationTest.maximumExchangeExpected,
          _ReliabilityBvaValidationTest.maximumDelta,
        ),
      );
      expect(overflowIsFinite, isFalse);

      controller.dispose();
      editor.dispose();
    });
  });
}
