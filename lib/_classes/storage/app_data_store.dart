// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

// ignore_for_file: type=lint

import 'package:app_finance/_classes/controller/iterator_controller.dart';
import 'package:app_finance/_classes/storage/app_data_type.dart';
import 'package:app_finance/_classes/structure/interface_app_data.dart';

abstract interface class AppDataExchangeStore {
  dynamic add(InterfaceAppData value, [String? uuid]);

  dynamic getByUuid(String uuid, [bool isClone = true]);
}

abstract interface class AppDataStore extends AppDataExchangeStore {
  AppDataExchangeStore get exchangeStore;

  @override
  dynamic add(InterfaceAppData value, [String? uuid]);

  void update(String uuid, InterfaceAppData value, [bool createIfMissing = false]);

  @override
  dynamic getByUuid(String uuid, [bool isClone = true]);

  double getTotal(AppDataType property);

  List<dynamic> getList(AppDataType property, [bool isClone = true]);

  List<dynamic> getActualList(AppDataType property, [bool isClone = true]);

  InterfaceIterator getStream<M extends InterfaceAppData>(AppDataType property,
      {bool inverse = true, double? boundary, Function? filter});
}
