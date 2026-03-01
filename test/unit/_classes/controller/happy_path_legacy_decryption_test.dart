// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:app_finance/_classes/controller/encryption_handler.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};

  setUp(() {
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final key = args['key'] as String?;

      switch (call.method) {
        case 'read':
          return storage[key];
        case 'write':
          if (key != null) {
            storage[key] = args['value'] as String;
          }

          return null;
        case 'delete':
          if (key != null) {
            storage.remove(key);
          }

          return null;
      }

      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test(
    '[Happy Path] should decrypt legacy hardcoded-key payload after initialization',
    () async {
      const legacyPlainText = 'legacy-user-record';
      final legacyCipher = Encrypter(
        AES(Key.fromUtf8('tercad-app-finance-by-vlyskouski')),
      ).encrypt(legacyPlainText, iv: IV.fromLength(8)).base64;

      await EncryptionHandler.initialize();

      expect(EncryptionHandler.decrypt(legacyCipher), legacyPlainText);
    },
  );
}
