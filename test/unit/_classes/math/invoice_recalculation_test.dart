// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

// ignore_for_file: type=lint

import 'package:app_finance/_classes/math/invoice_recalculation.dart';
import 'package:app_finance/_classes/structure/account_app_data.dart';
import 'package:app_finance/_classes/structure/currency/exchange.dart';
import 'package:app_finance/_classes/storage/app_data.dart';
import 'package:app_finance/_classes/structure/invoice_app_data.dart';
import 'package:dart_class_wrapper/dart_class_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

@GenerateWithMethodSetters([InvoiceRecalculation])
import 'invoice_recalculation_test.wrapper.dart';
@GenerateNiceMocks([MockSpec<AppData>()])
import 'invoice_recalculation_test.mocks.dart';

void main() {
  group('InvoiceRecalculation', () {
    late InvoiceRecalculation object;

    setUp(() {
      final billMock = InvoiceAppData(
        uuid: '1',
        title: 'test',
        account: '',
      );
      object = InvoiceRecalculation(
        billMock.clone(),
        billMock.clone(),
      );
      object.exchange = Exchange(store: MockAppData());
    });

    test('getDelta (UnimplementedError)', () {
      expect(() => object.getDelta(), throwsA(isA<UnimplementedError>()));
    });

    group('getStateDelta', () {
      final testCases = [
        (
          initial: (hidden: true, uuid: '1', details: 10.0),
          change: (hidden: true, uuid: '2', details: 20.0),
          result: 0.0,
        ),
        (
          initial: (hidden: false, uuid: '1', details: 10.0),
          change: (hidden: false, uuid: '2', details: 20.0),
          result: 20.0,
        ),
        (
          initial: (hidden: false, uuid: '1', details: 10.0),
          change: (hidden: false, uuid: '1', details: 20.0),
          result: 10.0,
        ),
        (
          initial: (hidden: false, uuid: '1', details: 10.0),
          change: (hidden: true, uuid: '1', details: 20.0),
          result: -10.0,
        ),
        (
          initial: (hidden: true, uuid: '1', details: 10.0),
          change: (hidden: false, uuid: '1', details: 20.0),
          result: 20.0,
        ),
        (
          initial: null,
          change: (hidden: false, uuid: '1', details: 20.0),
          result: 20.0,
        ),
      ];

      for (var v in testCases) {
        test('$v', () {
          if (v.initial == null) {
            object.initial = null;
          } else {
            object.initial!.hidden = v.initial!.hidden;
            object.initial!.details = v.initial!.details;
            object.initial!.uuid = v.initial!.uuid;
          }
          object.change.hidden = v.change.hidden;
          object.change.details = v.change.details;
          object.change.uuid = v.change.uuid;
          expect(object.getStateDelta(object.initial, object.change), v.result);
        });
      }
    });
    group('getPrevDelta', () {
      final testCases = [
        (
          initial: (hidden: true, details: 10.0),
          result: 0.0,
        ),
        (
          initial: (hidden: false, details: 10.0),
          result: 10.0,
        ),
      ];

      for (var v in testCases) {
        test('$v', () {
          object.initial!.hidden = v.initial.hidden;
          object.initial!.details = v.initial.details;
          expect(object.getPrevDelta(), v.result);
        });
      }
    });

    group('updateAccount', () {
      final testCases = [
        (
          getStateDelta: 10.0,
          getPrevDelta: 0.0,
          initial: (createdAtFormatted: '2023-07-17 00:00:00'),
          initialAccount: (createdAtFormatted: '2023-07-10 00:00:00', uuid: '1'),
          change: (createdAtFormatted: '2023-07-17 00:00:00'),
          changeAccount: (createdAtFormatted: '2023-07-10 00:00:00', uuid: '1'),
          result: (initialAccountDetails: 0.0, changeAccountDetails: 10.0),
        ),
        (
          getStateDelta: 20.0,
          getPrevDelta: 10.0,
          initial: (createdAtFormatted: '2023-07-17 00:00:00'),
          initialAccount: (createdAtFormatted: '2023-07-10 00:00:00', uuid: '1'),
          change: (createdAtFormatted: '2023-07-17 00:00:00'),
          changeAccount: (createdAtFormatted: '2023-07-10 00:00:00', uuid: '2'),
          result: (initialAccountDetails: -10.0, changeAccountDetails: 20.0),
        ),
        (
          getStateDelta: 20.0,
          getPrevDelta: 10.0,
          initial: (createdAtFormatted: '2023-07-17 00:00:00'),
          initialAccount: (createdAtFormatted: '2023-07-20 00:00:00', uuid: '1'),
          change: (createdAtFormatted: '2023-07-17 00:00:00'),
          changeAccount: (createdAtFormatted: '2023-07-20 00:00:00', uuid: '2'),
          result: (initialAccountDetails: 0.0, changeAccountDetails: 0.0),
        ),
        (
          getStateDelta: 20.0,
          getPrevDelta: 10.0,
          initial: (createdAtFormatted: '2023-07-17 00:00:00'),
          initialAccount: (createdAtFormatted: '2023-07-10 00:00:00', uuid: '1'),
          change: (createdAtFormatted: '2023-07-17 00:00:00'),
          changeAccount: (createdAtFormatted: '2023-07-20 00:00:00', uuid: '2'),
          result: (initialAccountDetails: -10.0, changeAccountDetails: 0.0),
        ),
      ];

      for (var v in testCases) {
        test('$v', () {
          object.initial!.createdAtFormatted = v.initial.createdAtFormatted;
          object.change.createdAtFormatted = v.change.createdAtFormatted;
          final mock = WrapperInvoiceRecalculation(
            object.change,
            object.initial,
          );
          mock.exchange = object.exchange;
          mock.mockGetStateDelta = (a, b) => v.getStateDelta;
          mock.mockGetPrevDelta = () => v.getPrevDelta;
          final initial = AccountAppData(title: '', type: '')
            ..uuid = v.initialAccount.uuid
            ..createdAtFormatted = v.initialAccount.createdAtFormatted;
          final change = AccountAppData(title: '', type: '')
            ..uuid = v.changeAccount.uuid
            ..createdAtFormatted = v.changeAccount.createdAtFormatted;
          mock.updateAccount(change, initial);
          expect(initial.details, v.result.initialAccountDetails);
          expect(change.details, v.result.changeAccountDetails);
        });
      }

      test('applies reverse flow for account migration and target account update', () {
        object.initial!.createdAtFormatted = '2026-03-04 00:00:00';
        object.change.createdAtFormatted = '2026-03-04 00:00:00';

        final mock = WrapperInvoiceRecalculation(
          object.change,
          object.initial,
        )..exchange = object.exchange;
        mock.mockGetStateDelta = (a, b) => 20.0;
        mock.mockGetPrevDelta = () => 10.0;

        final initial = AccountAppData(title: '', type: '')
          ..uuid = 'initial-account'
          ..createdAtFormatted = '2026-03-03 00:00:00';
        final change = AccountAppData(title: '', type: '')
          ..uuid = 'change-account'
          ..createdAtFormatted = '2026-03-03 00:00:00';

        mock.updateAccount(change, initial, true);

        expect(initial.details, -10.0);
        expect(change.details, -20.0);
      });

      test('skips migration branch when previous account is absent', () {
        object.initial!.createdAtFormatted = '2026-03-04 00:00:00';
        object.change.createdAtFormatted = '2026-03-04 00:00:00';

        final mock = WrapperInvoiceRecalculation(
          object.change,
          object.initial,
        )..exchange = object.exchange;
        mock.mockGetStateDelta = (a, b) => 15.0;
        mock.mockGetPrevDelta = () => 99.0;

        final change = AccountAppData(title: '', type: '')
          ..uuid = 'change-account'
          ..createdAtFormatted = '2026-03-03 00:00:00';

        mock.updateAccount(change, null);

        expect(change.details, 15.0);
      });

      test('does not adjust target account when change account is newer than invoice', () {
        object.initial!.createdAtFormatted = '2026-03-04 00:00:00';
        object.change.createdAtFormatted = '2026-03-04 00:00:00';

        final mock = WrapperInvoiceRecalculation(
          object.change,
          object.initial,
        )..exchange = object.exchange;
        mock.mockGetStateDelta = (a, b) => 20.0;
        mock.mockGetPrevDelta = () => 10.0;

        final initial = AccountAppData(title: '', type: '')
          ..uuid = 'initial-account'
          ..createdAtFormatted = '2026-03-03 00:00:00';
        final change = AccountAppData(title: '', type: '')
          ..uuid = 'change-account'
          ..createdAtFormatted = '2026-03-05 00:00:00';

        mock.updateAccount(change, initial);

        expect(initial.details, -10.0);
        expect(change.details, 0.0);
      });
    });
  });
}
