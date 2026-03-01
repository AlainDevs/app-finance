// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:app_finance/_classes/controller/secure_aes_key_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  const storageKey = 'app_finance_aes_key_v1';
  const keyLength = 32;

  final storage = <String, String>{};

  setUp(() {
    storage.clear();
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
      }

      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('warmUp creates and persists a new key when storage is empty', () async {
    await SecureAesKeyProvider.warmUp();

    final generated = SecureAesKeyProvider.cachedKey;
    final encoded = storage[storageKey];

    expect(encoded, isNotNull);
    final restoredBytes = base64Decode(encoded!);
    expect(restoredBytes.length, keyLength);
    expect(restoredBytes, generated.bytes);
    expect(SecureAesKeyProvider.keyOrLegacy.bytes, generated.bytes);
  });
}
