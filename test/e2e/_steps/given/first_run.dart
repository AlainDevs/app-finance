// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:flutter_gherkin_wrapper/flutter_gherkin_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages, because of the gherkin package
import 'package:gherkin/gherkin.dart';

import 'package:app_finance/_configs/test_keys.dart';

class FirstRun extends Given {
  @override
  RegExp get pattern => RegExp(r"I am firstly opened the app");

  @override
  Future<void> executeStep() async {
    final loading = find.byKey(TestKeys.homeInitializationPage);
    while (loading.evaluate().isNotEmpty) {
      await FileRunner.tester.pumpAndSettle();
    }
    await FileRunner.tester.pumpAndSettle();
  }
}
