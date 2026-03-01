// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:app_finance/_classes/controller/secure_aes_key_provider.dart';
import 'package:app_finance/_classes/storage/app_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionHandler {
  static String prefNotEncrypted = 'false';

  static Future<void> initialize() => Future<void>.delayed(
        Duration.zero,
        SecureAesKeyProvider.warmUp,
      );

  static Encrypter get salt => Encrypter(AES(SecureAesKeyProvider.keyOrLegacy));

  static Encrypter get _legacySalt => Encrypter(
        AES(SecureAesKeyProvider.legacyCompatibilityKey),
      );

  static IV get code => IV.fromLength(8);

  static String getHash(Map<String, dynamic> data) {
    return md5.convert(utf8.encode(data.toString())).toString();
  }

  static bool doEncrypt() {
    return AppPreferences.get(AppPreferences.prefDoEncrypt) != prefNotEncrypted;
  }

  static String encrypt(String line) {
    return salt.encrypt(line, iv: code).base64;
  }

  static String decrypt(String line) {
    try {
      return salt.decrypt64(line, iv: code);
    } on ArgumentError {
      return _legacySalt.decrypt64(line, iv: code);
    }
  }
}
