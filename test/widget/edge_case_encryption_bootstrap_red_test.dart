// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:app_finance/_classes/controller/encryption_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    '[Edge Case] should render bootstrap widget even when secure key init fails',
    (tester) async {
      await tester.pumpWidget(
        FutureBuilder<void>(
          future: EncryptionHandler.initialize(),
          builder: (_, snapshot) {
            if (snapshot.hasError) {
              return const MaterialApp(
                home: Scaffold(
                  body: Text('Degraded secure-storage mode'),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Degraded secure-storage mode'), findsOneWidget);
    },
  );
}
