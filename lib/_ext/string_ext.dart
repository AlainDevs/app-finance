// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:characters/characters.dart';

extension StringExt on String {
  static const _mapEnvelopeLength = 2;
  static const _pairLength = 2;
  static const _keyGroupIndex = 1;
  static const _valueGroupIndex = 2;

  T _asType<T>(String value) {
    if (T == int) {
      return int.tryParse(value) as T;
    }
    if (T == double) {
      return double.tryParse(value) as T;
    }
    if (T == String) {
      return value.toString() as T;
    }

    return null as T;
  }

  Map<T, K> toMap<T, K>() {
    if (isEmpty || characters.length < _mapEnvelopeLength) {
      return <T, K>{};
    }

    final content = characters.skip(1).take(characters.length - _mapEnvelopeLength).toString();
    final data = content.split(',');
    final Map<T, K> result = {};
    for (final pair in data) {
      final parts = pair.split(':');
      if (parts.length != _pairLength) {
        continue;
      }

      final key = _asType<T>(parts.first.trim());
      result[key] = _asType<K>(parts[1].trim());
    }

    return result;
  }

  String _wrap() {
    if (contains('{')) {
      final pattern = RegExp(r'(\w+):\s*([\w\.\- ]+)');

      return replaceAllMapped(pattern, (match) {
        final key = match.group(_keyGroupIndex) ?? '_';
        final value = match.group(_valueGroupIndex)?.trim() ?? '';

        return '"$key": ${num.tryParse(value) ?? '"$value"'}';
      });
    }

    return this;
  }

  List<T> toList<T>() {
    final data = length > 0 ? json.decode(_wrap()) : [];
    final List<T> result = [];
    for (final value in data) {
      result.add(value);
    }

    return result;
  }

  T toEnum<T>(List<T> values) => values.firstWhere((e) => e.toString() == this);

  int toInt() => int.parse(this);
}
