// Copyright 2026 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can
// be found in the LICENSE file.

import 'package:app_finance/_classes/herald/app_locale.dart';
import 'package:app_finance/_classes/storage/app_preferences.dart';
import 'package:app_finance/_classes/structure/currency/exchange.dart';
import 'package:app_finance/components/_core/component_data.dart';
import 'package:app_finance/components/component_recent.dart';
import 'package:app_finance/l10n/app_localization_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _evaluateBuild(
  WidgetTester tester, {
  required ComponentRecentType type,
  required dynamic countValue,
}) async {
  SharedPreferences.setMockInitialValues({
    AppPreferences.prefZoom: '1.0',
    AppPreferences.prefCurrency: 'EUR',
  });
  AppPreferences.pref = await SharedPreferences.getInstance();
  AppLocale.labels = AppLocalizationsEn();
  Exchange.defaultCurrency = null;

  final data = <String, dynamic>{
    componentData.order: 0,
    ComponentRecent.type: type.toString(),
    ComponentRecent.count: countValue,
  };

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          ComponentRecent(data).build(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

void main() {
  testWidgets('ComponentRecent handles string count parsing', (tester) async {
    await _evaluateBuild(
      tester,
      type: ComponentRecentType.account,
      countValue: '11',
    );

    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('ComponentRecent handles double count parsing', (tester) async {
    await _evaluateBuild(
      tester,
      type: ComponentRecentType.payment,
      countValue: 9.2,
    );

    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('ComponentRecent handles int count parsing', (tester) async {
    await _evaluateBuild(
      tester,
      type: ComponentRecentType.account,
      countValue: 3,
    );

    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('ComponentRecent handles fallback count parsing', (tester) async {
    await _evaluateBuild(
      tester,
      type: ComponentRecentType.account,
      countValue: {'unexpected': true},
    );

    expect(find.byType(SizedBox), findsOneWidget);
  });
}
