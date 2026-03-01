// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:app_finance/_classes/controller/encryption_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const invalidKeyLength = 31;
  const repeatedByte = 7;

  const channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};

  setUp(() {
    storage
      ..clear()
      ..['app_finance_aes_key_v1'] = base64Encode(
        List<int>.filled(
          invalidKeyLength,
          repeatedByte,
          growable: false,
        ),
      );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, Object?>() ?? <String, Object?>{};
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
    '[Boundary] should fail initialization when stored AES key has 31 bytes',
    () async {
      expect(
        EncryptionHandler.initialize,
        throwsA(isA<FormatException>()),
      );
    },
  );
}
