// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:app_finance/_classes/controller/secure_aes_key_provider.dart';
import 'package:encrypt/encrypt.dart';
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

  test('cachedKey throws before initialization', () {
    expect(
      () => SecureAesKeyProvider.cachedKey,
      throwsA(isA<StateError>()),
    );
  });

  test('warmUp deduplicates concurrent load calls', () async {
    final bytes = List<int>.generate(
      keyLength,
      (i) => i,
      growable: false,
    );
    storage[storageKey] = base64Encode(bytes);

    final readGate = Completer<void>();
    var readCalls = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, Object?>() ?? <String, Object?>{};
      final key = args['key'] as String?;

      switch (call.method) {
        case 'read':
          readCalls += 1;
          await readGate.future;
          return storage[key];
        case 'write':
          if (key != null) {
            storage[key] = args['value'] as String;
          }

          return null;
      }

      return null;
    });

    final firstWarmUp = SecureAesKeyProvider.warmUp();
    final secondWarmUp = SecureAesKeyProvider.warmUp();

    await Future<void>.delayed(Duration.zero);
    readGate.complete();

    await Future.wait(<Future<void>>[firstWarmUp, secondWarmUp]);

    expect(readCalls, 1);
    expect(SecureAesKeyProvider.cachedKey.bytes, bytes);
  });

  test('warmUp reads and restores an existing key', () async {
    final bytes = List<int>.generate(
      keyLength,
      (i) => i,
      growable: false,
    );
    storage[storageKey] = base64Encode(bytes);

    await SecureAesKeyProvider.warmUp();

    expect(SecureAesKeyProvider.cachedKey.bytes, bytes);
    expect(SecureAesKeyProvider.keyOrLegacy.bytes, bytes);
  });

  test('legacyCompatibilityKey remains stable', () {
    expect(
      SecureAesKeyProvider.legacyCompatibilityKey.bytes,
      Key.fromUtf8('tercad-app-finance-by-vlyskouski').bytes,
    );
  });
}
