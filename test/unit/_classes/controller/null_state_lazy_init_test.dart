// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:app_finance/_classes/controller/encryption_handler.dart';
import 'package:app_finance/_classes/controller/secure_aes_key_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '[Null/State] cachedKey should throw when key is not initialized',
    () {
      expect(
        () => SecureAesKeyProvider.cachedKey,
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    '[Null/State] should lazily initialize key when encrypt is called before initialize',
    () {
      const payload = 'state-dependent payload';

      final encrypted = EncryptionHandler.encrypt(payload);

      expect(encrypted, isNotEmpty);
      expect(EncryptionHandler.decrypt(encrypted), payload);
    },
  );
}
