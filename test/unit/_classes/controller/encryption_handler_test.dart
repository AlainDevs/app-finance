// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:app_finance/_classes/controller/encryption_handler.dart';
import 'package:app_finance/_classes/controller/secure_aes_key_provider.dart';
import 'package:app_finance/_classes/storage/app_preferences.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateNiceMocks([MockSpec<SharedPreferences>()])
import 'encryption_handler_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const expectedStaticIvLength = 8;
  const aesKeyLengthInBytes = 32;
  const warmUpTestKeyByte = 7;
  const expectedEnvelopePartsCount = 3;
  const dynamicKeySeedOffset = 1;

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  const secureStorageKey = 'app_finance_aes_key_v1';
  final secureStorage = <String, String>{};

  setUp(() {
    AppPreferences.pref = MockSharedPreferences();
    secureStorage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel,
        (call) async {
      final args = (call.arguments as Map?)?.cast<String, Object?>() ?? <String, Object?>{};
      final key = args['key'] as String?;

      switch (call.method) {
        case 'read':
          return secureStorage[key];
        case 'write':
          if (key != null) {
            secureStorage[key] = args['value'] as String;
          }

          return null;
      }

      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  group('EncryptionHandler', () {
    test('code has expected static iv length', () {
      expect(EncryptionHandler.code.bytes.length, expectedStaticIvLength);
    });

    test('getHash', () {
      final data = <String, dynamic>{'test': 123};
      expect(EncryptionHandler.getHash(data), 'ff4123302616ba02c74a95824d40f192');
    });

    test('initialize completes by triggering secure key provider warm-up', () async {
      secureStorage[secureStorageKey] = base64Encode(
        List<int>.filled(aesKeyLengthInBytes, warmUpTestKeyByte),
      );

      await expectLater(EncryptionHandler.initialize(), completes);
    });

    group('doEncrypt', () {
      final testCases = [
        (getPreference: null, result: true),
        (getPreference: 'true', result: true),
        (getPreference: 'false', result: false),
      ];

      for (var v in testCases) {
        test('$v', () {
          when(AppPreferences.pref.getString('doEncrypt')).thenReturn(v.getPreference);
          expect(EncryptionHandler.doEncrypt(), v.result);
        });
      }
    });

    test('encrypt / decrypt', () {
      const data = 'sample content';
      final enc = EncryptionHandler.encrypt(data);

      final envelopeParts = enc.split(':');
      expect(envelopeParts.length, expectedEnvelopePartsCount);
      expect(envelopeParts.first, 'v2');
      expect(envelopeParts[1], isNotEmpty);
      expect(envelopeParts[2], isNotEmpty);

      expect(EncryptionHandler.decrypt(enc), data);
    });

    test('encrypt uses dynamic IV and produces non-deterministic ciphertext', () {
      const data = 'same input';

      final first = EncryptionHandler.encrypt(data);
      final second = EncryptionHandler.encrypt(data);

      expect(first, isNot(equals(second)));
      expect(EncryptionHandler.decrypt(first), data);
      expect(EncryptionHandler.decrypt(second), data);
    });

    test('decrypt supports legacy static-IV ciphertext encrypted with current key', () async {
      await EncryptionHandler.initialize();

      const plainText = 'current-key legacy-format content';
      final legacyEncryptedByCurrentKey = Encrypter(
        AES(SecureAesKeyProvider.keyOrLegacy),
      ).encrypt(plainText, iv: EncryptionHandler.code).base64;

      expect(EncryptionHandler.decrypt(legacyEncryptedByCurrentKey), plainText);
    });

    test('decrypt falls back to legacy key when current key fails', () async {
      final usesLegacyByDefault = base64Encode(SecureAesKeyProvider.keyOrLegacy.bytes) ==
          base64Encode(SecureAesKeyProvider.legacyCompatibilityKey.bytes);
      if (usesLegacyByDefault) {
        secureStorage[secureStorageKey] = base64Encode(
          List<int>.generate(
            aesKeyLengthInBytes,
            (i) => i + dynamicKeySeedOffset,
            growable: false,
          ),
        );
        await EncryptionHandler.initialize();
      }

      const plainText = 'legacy encrypted content';
      final legacyEncrypted = Encrypter(
        AES(SecureAesKeyProvider.legacyCompatibilityKey),
      ).encrypt(plainText, iv: EncryptionHandler.code).base64;

      expect(EncryptionHandler.decrypt(legacyEncrypted), plainText);
    });

    test('decrypt rethrows non-argument errors (invalid base64)', () {
      expect(
        () => EncryptionHandler.decrypt('not-base64-@@@'),
        throwsA(isA<FormatException>()),
      );
    });

    test('salt uses active key from provider', () {
      const payload = 'salt-backed-value';
      final encryptedBySalt = EncryptionHandler.salt.encrypt(payload, iv: EncryptionHandler.code);
      final decryptedByDirect = Encrypter(
        AES(SecureAesKeyProvider.keyOrLegacy),
      ).decrypt64(encryptedBySalt.base64, iv: EncryptionHandler.code);

      expect(decryptedByDirect, payload);
    });
  });
}
