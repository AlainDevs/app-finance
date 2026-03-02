// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:app_finance/_classes/storage/app_data_store.dart';

mixin StorageMixin {
  AppDataStore? _state;

  StorageMixin setState(AppDataStore state) {
    _state = state;

    return this;
  }

  AppDataStore getState() {
    final state = _state;
    if (state == null) {
      throw StateError('Storage is not attached. Call setState first.');
    }

    return state;
  }
}
