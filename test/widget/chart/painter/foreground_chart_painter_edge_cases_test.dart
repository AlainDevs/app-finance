// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

// ignore_for_file: no-magic-number, prefer-moving-to-variable

import 'dart:ui' as ui;

import 'package:app_finance/charts/painter/foreground_chart_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../pump_main.dart';

void main() {
  testWidgets('ForegroundChartPainter paints icon and percentage paths', (tester) async {
    await PumpMain.initPaint(
      tester,
      ForegroundChartPainter(
        size: const Size(720, 480),
        yDivider: 4,
        xDivider: 4,
        yType: IconData,
        yMap: const [
          Icons.add,
          Icons.remove,
          Icons.check,
          Icons.close,
        ],
      ),
      const Size(720, 480),
    );

    await tester.pumpAndSettle();

    await PumpMain.initPaint(
      tester,
      ForegroundChartPainter(
        size: const Size(720, 480),
        yDivider: 4,
        xDivider: 4,
        yType: Percentage,
      ),
      const Size(720, 480),
    );

    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsOneWidget);
  });

  testWidgets('ForegroundChartPainter covers DateTime x-axis and mid text area branch', (tester) async {
    final painter = ForegroundChartPainter(
      size: const Size(500, 500),
      xDivider: 4,
      yDivider: 4,
      xType: DateTime,
      xMin: DateTime(2026, 1, 1).millisecondsSinceEpoch.toDouble(),
      xMax: DateTime(2026, 1, 6).millisecondsSinceEpoch.toDouble(),
      yType: Percentage,
      yMin: 0,
      yMax: 100,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    painter.paint(canvas, const Size(500, 500));

    final picture = recorder.endRecording();

    expect(painter.textArea, 25);
    expect(picture, isNotNull);
  });
}
