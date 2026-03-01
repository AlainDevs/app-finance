// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gherkin_wrapper/flutter_gherkin_wrapper.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/e2e/e2e_test.list.dart';
import '../../test/e2e/_steps/given/first_run.dart';
import '../../test/pump_main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  ExecutableStepIterator.inject(classList);

  testWidgets('Cover Starting Page', (WidgetTester tester) async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear();
    await PumpMain.init(tester, true);

    FileRunner.tester = tester;
    await FirstRun().executeStep();

    expect(find.text('Initial Setup'), findsOneWidget);
  });
}
