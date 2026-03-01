// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:app_finance/_classes/controller/secure_aes_key_provider.dart';
import 'package:app_finance/_classes/storage/app_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionHandler {
  static const String prefNotEncrypted = 'false';
  static const int _ivLength = 8;
  static const String _cipherVersion = 'v2';
  static const String _envelopeDelimiter = ':';
  static const int _envelopePartsCount = 3;

  static IV get code => IV.fromLength(_ivLength);

  static Encrypter get salt => Encrypter(AES(SecureAesKeyProvider.keyOrLegacy));

  static Encrypter get _legacySalt => Encrypter(
        AES(SecureAesKeyProvider.legacyCompatibilityKey),
      );

  static Future<void> initialize() => Future<void>.delayed(
        Duration.zero,
        SecureAesKeyProvider.warmUp,
      );

  static String getHash(Map<String, dynamic> data) {
    return md5.convert(utf8.encode(data.toString())).toString();
  }

  static bool doEncrypt() {
    return AppPreferences.get(AppPreferences.prefDoEncrypt) != prefNotEncrypted;
  }

  static String encrypt(String line) {
    final iv = IV.fromSecureRandom(_ivLength);
    final cipherText = salt.encrypt(line, iv: iv).base64;

    return '$_cipherVersion$_envelopeDelimiter${iv.base64}$_envelopeDelimiter$cipherText';
  }

  static String decrypt(String line) {
    if (line.startsWith('$_cipherVersion$_envelopeDelimiter')) {
      final envelopeParts = line.split(_envelopeDelimiter);
      if (envelopeParts.length != _envelopePartsCount || envelopeParts[1].isEmpty || envelopeParts[2].isEmpty) {
        throw const FormatException('Invalid encrypted payload format.');
      }

      final iv = IV.fromBase64(envelopeParts[1]);

      return _decryptWithFallback(envelopeParts[2], iv: iv);
    }

    return _decryptWithFallback(line, iv: code);
  }

  static String _decryptWithFallback(String line, {required IV iv}) {
    try {
      return salt.decrypt64(line, iv: iv);
    } on ArgumentError {
      return _legacySalt.decrypt64(line, iv: iv);
    }
  }
}
