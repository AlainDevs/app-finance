// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:app_finance/_classes/math/abstract_recalculation.dart';
import 'package:app_finance/_classes/storage/history_data.dart';
import 'package:app_finance/_classes/structure/abstract_app_data.dart';
import 'package:app_finance/_classes/structure/account_app_data.dart';
import 'package:app_finance/_classes/structure/invoice_app_data.dart';

class InvoiceRecalculation extends AbstractRecalculation {
  InvoiceAppData change;
  InvoiceAppData? initial;

  InvoiceRecalculation(this.change, [this.initial]);

  @override
  double getDelta() => throw UnimplementedError();

  double getPrevDelta() => initial?.hidden == true ? 0.0 : initial?.details;

  double getStateDelta(AbstractAppData? prev, AbstractAppData? curr) {
    final delta = change.hidden ? 0.0 : change.details;
    final initialInvoice = initial;
    final isSameStateEntity = initialInvoice != null && prev?.uuid == curr?.uuid;
    if (!isSameStateEntity) {
      return delta;
    }

    if (change.hidden) {
      return -initialInvoice.details;
    }

    if (initialInvoice.hidden) {
      return change.details;
    }

    return change.details - initialInvoice.details;
  }

  void updateAccount(AccountAppData accountChange, AccountAppData? accountInitial, [bool reverse = false]) {
    final plex = reverse ? -1.0 : 1.0;
    final diffDelta = _getDiffDelta(accountChange, accountInitial, plex);
    final delta = getStateDelta(accountInitial, accountChange);

    _logUpdatedAccount(accountChange, delta, plex);
    _applyInitialAccountDelta(accountInitial, diffDelta, plex);
    _applyChangedAccountDelta(accountChange, delta, plex);
  }

  double? _getDiffDelta(
    AccountAppData accountChange,
    AccountAppData? accountInitial,
    double plex,
  ) {
    final initialInvoice = initial;
    final shouldApplyDiff =
        accountInitial != null && initialInvoice != null && accountChange.uuid != accountInitial.uuid;
    if (!shouldApplyDiff) {
      return null;
    }

    final diffDelta = plex * getPrevDelta();
    HistoryData.addLog(
      accountInitial.uuid ?? '',
      initialInvoice,
      0.0,
      -diffDelta,
      initialInvoice.uuid,
    );

    return diffDelta;
  }

  void _logUpdatedAccount(
    AccountAppData accountChange,
    double delta,
    double plex,
  ) {
    HistoryData.addLog(
      accountChange.uuid ?? '',
      change,
      0.0,
      delta * plex,
      change.uuid,
    );
  }

  void _applyInitialAccountDelta(
    AccountAppData? accountInitial,
    double? diffDelta,
    double plex,
  ) {
    final initialInvoice = initial;
    final initialAccount = accountInitial;
    if (diffDelta == null || initialAccount == null) {
      return;
    }

    final canUpdateInitial = initialAccount.createdAt.isBefore(initialInvoice?.createdAt ?? DateTime.now());
    if (!canUpdateInitial) {
      return;
    }

    initialAccount.details -= plex *
        super.exchange.reform(
              diffDelta,
              initialInvoice?.currency,
              initialAccount.currency,
            );
  }

  void _applyChangedAccountDelta(
    AccountAppData accountChange,
    double delta,
    double plex,
  ) {
    if (!accountChange.createdAt.isBefore(change.createdAt)) {
      return;
    }

    accountChange.details += plex * super.exchange.reform(delta, change.currency, accountChange.currency);
  }
}
