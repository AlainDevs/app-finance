// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:app_finance/_classes/storage/app_data_store.dart';
import 'package:app_finance/_mixins/storage_mixin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _StorageMixinTest with StorageMixin {}

class _MockAppDataStore extends Mock implements AppDataStore {}

void main() {
  group('StorageMixin', () {
    test('getState throws StateError when state is not attached', () {
      final carrier = _StorageMixinTest();

      expect(
        carrier.getState,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Storage is not attached. Call setState first.',
          ),
        ),
      );
    });

    test('setState stores and returns the same carrier instance', () {
      final carrier = _StorageMixinTest();
      final store = _MockAppDataStore();

      final result = carrier.setState(store);

      expect(identical(result, carrier), isTrue);
      expect(identical(carrier.getState(), store), isTrue);
    });
  });
}
