// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureAesKeyProvider {
  static const _storageKey = 'app_finance_aes_key_v1';
  static const _aesKeyLength = 32;
  static const _maxRandomByte = 256;
  static const _storage = FlutterSecureStorage();
  static const _legacyKeyUtf8 = 'tercad-app-finance-by-vlyskouski';

  static Key? _cachedKey;
  static Future<Key>? _pending;
  static Future<String?>? _pendingRead;

  static final Key _legacyCompatibilityKey = Key.fromUtf8(_legacyKeyUtf8);

  static Key get cachedKey {
    final key = _cachedKey;
    if (key == null) {
      throw StateError('Encryption key is not initialized.');
    }

    return key;
  }

  static Key get keyOrLegacy => _cachedKey ?? _legacyCompatibilityKey;

  static Key get legacyCompatibilityKey => _legacyCompatibilityKey;

  static Future<void> warmUp() async {
    _cachedKey ??= await _loadOrCreate();
  }

  static Future<Key> _loadOrCreate() {
    final currentOperation = _pending;
    if (currentOperation != null) {
      return currentOperation;
    }

    return _pending = _readOrCreate().whenComplete(() => _pending = null);
  }

  static Future<String?> _readStoredValue() {
    return _pendingRead ??= _storage.read(key: _storageKey).whenComplete(() {
      _pendingRead = null;
    });
  }

  static Future<Key> _readOrCreate() async {
    // ignore: prefer-moving-to-variable, deduplicated storage read path
    final encoded = await _readStoredValue();
    if (encoded != null) {
      final restored = _toKey(encoded);
      _cachedKey = restored;

      return restored;
    }

    final generated = _generateKey();
    await _storage.write(
      key: _storageKey,
      value: base64Encode(generated.bytes),
    );
    // ignore: prefer-moving-to-variable, deduplicated storage read path
    final writtenBack = await _readStoredValue();
    if (writtenBack == null) {
      throw const FormatException(
        'Unable to persist AES key in secure storage.',
      );
    }
    _toKey(writtenBack);
    _cachedKey = generated;

    return generated;
  }

  static Key _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      _aesKeyLength,
      (_) => random.nextInt(_maxRandomByte),
      growable: false,
    );

    return Key(Uint8List.fromList(bytes));
  }

  static Key _toKey(String encoded) {
    final bytes = base64Decode(encoded);
    if (bytes.length != _aesKeyLength) {
      throw const FormatException('Stored key has an unexpected length.');
    }

    return Key(Uint8List.fromList(bytes));
  }
}
