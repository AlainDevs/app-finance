// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/pump_main.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ignore: missing-test-assertion, because this test is only intended to warm up the app and does not require any assertions
  testWidgets('Warm-up', (WidgetTester tester) async {
    await PumpMain.init(tester, true);
    await tester.pumpAndSettle();
  });
}
