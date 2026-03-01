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
  static const _storage = FlutterSecureStorage();

  static Key? _cachedKey;
  static Future<Key>? _pending;

  static Key get cachedKey {
    final key = _cachedKey;
    if (key == null) {
      throw StateError('Encryption key is not initialized.');
    }
    return key;
  }

  static Future<void> warmUp() async {
    _cachedKey ??= await _loadOrCreate();
  }

  static Future<Key> _loadOrCreate() {
    final current = _cachedKey;
    if (current != null) {
      return Future.value(current);
    }
    return _pending ??= _readOrCreate().whenComplete(() => _pending = null);
  }

  static Future<Key> _readOrCreate() async {
    final encoded = await _storage.read(key: _storageKey);
    if (encoded != null) {
      try {
        final restored = _toKey(encoded);
        _cachedKey = restored;
        return restored;
      } on FormatException {
        await _storage.delete(key: _storageKey);
      }
    }

    final generated = _generateKey();
    await _storage.write(
      key: _storageKey,
      value: base64Encode(generated.bytes),
    );
    _cachedKey = generated;
    return generated;
  }

  static Key _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      _aesKeyLength,
      (_) => random.nextInt(256),
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
