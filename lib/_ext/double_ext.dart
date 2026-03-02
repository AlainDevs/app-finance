// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'dart:math' as math;

extension DoubleExt on double {
  static const int _defaultFixedDigits = 8;
  static const int _decimalBase = 10;
  static const double _epsilon = 1e-10;

  double toFixed(int? digits) {
    if (!isFinite) {
      return this;
    }

    final safeDigits = digits ?? _defaultFixedDigits;
    final multiplier = math.pow(_decimalBase, safeDigits).toDouble();
    final scaledValue = this * multiplier;

    return scaledValue.round() / multiplier;
  }

  bool isEqual(double? value) {
    final comparableValue = value ?? 0;

    return (this - comparableValue).abs() < _epsilon;
  }

  bool isNotEqual(double? value) => !isEqual(value);
}
