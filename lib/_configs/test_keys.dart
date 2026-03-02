// Copyright 2026 AlainChan. All rights reserved.
// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Stable keys used by end-to-end and integration tests.
abstract final class TestKeys {
  static const openMainMenuButton = ValueKey<String>('navigation.open_main_menu_button');

  static const homeAddBillButton = ValueKey<String>('home.add_bill_income_transfer_button');
  static const accountAddButton = ValueKey<String>('account.add_button');
  static const budgetAddButton = ValueKey<String>('budget.add_button');

  static const accountTypeSelector = ValueKey<String>('account.form.type_selector');
  static const accountTitleInput = ValueKey<String>('account.form.title_input');
  static const accountBalanceInput = ValueKey<String>('account.form.balance_input');
  static const accountForm = ValueKey<String>('account.form.page');
  static const accountCreateButton = ValueKey<String>('account.form.create_button');

  static const budgetTitleInput = ValueKey<String>('budget.form.title_input');
  static const budgetBalanceInput = ValueKey<String>('budget.form.balance_input');
  static const budgetForm = ValueKey<String>('budget.form.page');
  static const budgetCreateButton = ValueKey<String>('budget.form.create_button');

  static const billAccountSelector = ValueKey<String>('bill.form.account_selector');
  static const billBudgetSelector = ValueKey<String>('bill.form.budget_selector');
  static const billAmountInput = ValueKey<String>('bill.form.amount_input');
  static const billDescriptionInput = ValueKey<String>('bill.form.description_input');
  static const billCreateButton = ValueKey<String>('bill.form.create_button');

  static const startPage = ValueKey<String>('start.initial_setup_page');
  static const homeInitializationPage = ValueKey<String>('home.initialization_page');
  static const listSelectorSearchInput = ValueKey<String>('selector.search_input');

  static const _menuPrefix = 'menu.item.';
  static const _selectorOptionPrefix = 'selector.option.';

  static ValueKey<String> menuItem(String route) {
    return ValueKey<String>('$_menuPrefix$route');
  }

  static ValueKey<String> selectorOption(String id) {
    return ValueKey<String>('$_selectorOptionPrefix$id');
  }
}
