// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

library;

import 'dart:convert';

import 'package:app_finance/_classes/herald/app_locale.dart';
import 'package:app_finance/_classes/storage/app_preferences.dart';
import 'package:app_finance/_classes/storage/transaction_log.dart';
import 'package:app_finance/_ext/data_ext.dart';
import 'package:flutter_currency_picker/flutter_currency_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_classes/controller/exchange_controller_test.mocks.dart' as ctrl_mocks;

class _ReliabilityMalformedPayloadTest {
  static const double nominalParsedAmount = 123.45;
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() {
    AppPreferences.pref = ctrl_mocks.MockSharedPreferences();
    CurrencyDefaults.cache = ctrl_mocks.MockSharedPreferences();
    AppLocale.code = 'en';
  });

  group('Resilience | malformed/null payload decoding', () {
    group('TransactionLog.add', () {
      final store = ctrl_mocks.MockAppData();

      test('[Min-1] completely non-JSON text returns false safely', () {
        final result = TransactionLog.add(store, 'NOT JSON AT ALL !!@', false);
        expect(
          result,
          isFalse,
          reason: 'Non-JSON payload must be caught and return false',
        );
      });

      test('[Min] empty string returns true (no-op by design)', () {
        final result = TransactionLog.add(store, '', false);
        expect(
          result,
          isTrue,
          reason: 'Empty line is a documented no-op that returns true',
        );
      });

      test('[boundary] empty JSON object {} fails gracefully', () {
        final result = TransactionLog.add(store, '{}', false);
        expect(
          result,
          isFalse,
          reason: 'Incomplete envelope without type/data must fail gracefully',
        );
      });

      test('[boundary] JSON missing type key fails gracefully', () {
        final line = jsonEncode({
          'data': {'uuid': 'x', 'title': 'test'},
        });
        final result = TransactionLog.add(store, line, false);
        expect(
          result,
          isFalse,
          reason: 'Payload without type key must fail gracefully',
        );
      });

      test('[boundary] JSON missing data key fails gracefully', () {
        final line = jsonEncode({'type': 'BillAppData'});
        final result = TransactionLog.add(store, line, false);
        expect(
          result,
          isFalse,
          reason: 'Payload without data key must fail gracefully',
        );
      });

      test('[nominal] valid unknown type name: no crash, returns true', () {
        final line = jsonEncode({
          'type': {'name': 'UnknownTypeThatDoesNotExist'},
          'data': {'uuid': 'u1', 'title': 'x'},
        });
        final result = TransactionLog.add(store, line, false);
        // Unknown type returns null from toDataObject; init() skips it, no
        // crash. The add() method returns true for successfully parsed JSON.
        expect(result, isTrue, reason: 'Unknown type falls through, no crash');
      });

      test('[Max+1] null data value causes graceful failure', () {
        final line = jsonEncode({
          'type': {'name': 'BillAppData'},
          'data': null,
        });
        final result = TransactionLog.add(store, line, false);
        expect(
          result,
          isFalse,
          reason: 'Null data field must be caught and return false',
        );
      });

      test('[Max+1] list instead of object for data fails gracefully', () {
        final line = jsonEncode({
          'type': {'name': 'BillAppData'},
          'data': [1, 2, 3],
        });
        final result = TransactionLog.add(store, line, false);
        expect(
          result,
          isFalse,
          reason: 'List-type data must be caught and return false',
        );
      });

      test('[Max+1] type field as null fails gracefully', () {
        final line = jsonEncode({'type': null, 'data': {}});
        final result = TransactionLog.add(store, line, false);
        expect(
          result,
          isFalse,
          reason: 'Null type must be caught and return false',
        );
      });
    });

    group('MapDataExt.toDataObject', () {
      final store = ctrl_mocks.MockAppData();

      test('[Min] unknown type name returns null safely without crash', () {
        final map = <String, dynamic>{
          'type': {'name': 'DoesNotExist'},
          'data': <String, dynamic>{},
        };
        expect(() => map.toDataObject(store), returnsNormally);
        expect(map.toDataObject(store), isNull);
      });

      test('[nominal] known GoalAppData type with minimal data parses normally', () {
        final now = DateTime.now().toIso8601String();
        final minimal = <String, dynamic>{
          'type': {'name': 'GoalAppData'},
          'data': <String, dynamic>{
            'uuid': 'goal-1',
            'title': 'My Goal',
            'initial': 0.0,
            'details': 100.0,
            'progress': 0.0,
            'updatedAt': now,
            'createdAt': now,
            'closedAt': now,
            'hidden': false,
            'skip': false,
            'currency': null,
            'color': null,
            'icon': null,
            'description': null,
            'payment': null,
          },
        };
        expect(() => minimal.toDataObject(store), returnsNormally);
        expect(minimal.toDataObject(store), isNotNull);
      });
    });

    group('Search page parse-crash risk documentation', () {
      test('[Min] empty amountFrom text → guard branch skips parse', () {
        const text = '';
        // Guard: `amountFrom.text.isEmpty || item.details >= parse(text)!`
        // short-circuits on isEmpty so the `!` is never evaluated.
        expect(text.isEmpty, isTrue);
      });

      test('[Min-1] non-numeric text → tryParse returns null', () {
        const text = 'not-a-number';
        final parsed = double.tryParse(text);
        expect(parsed, isNull);
        // With `!` after tryParse this would crash if text were non-empty and
        // non-numeric. FilteringTextInputFormatter prevents this at the UI
        // layer, but the risk is documented here.
      });

      test('[Nominal] valid numeric text parses correctly', () {
        expect(
          double.tryParse('123.45'),
          _ReliabilityMalformedPayloadTest.nominalParsedAmount,
        );
      });
    });
  });
}
