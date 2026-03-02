// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_finance/_configs/test_keys.dart';
import 'package:app_finance/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Cover Starting Page', (WidgetTester tester) async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear();

    app.main();

    final loading = find.byKey(TestKeys.homeInitializationPage);
    while (loading.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
    }
    await tester.pumpAndSettle();

    expect(find.byKey(TestKeys.startPage), findsOneWidget);
  });
}
