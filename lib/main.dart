// Copyright 2023 The terCAD team. All rights reserved.
// Use of this source code is governed by a CC BY-NC-ND 4.0 license that can be found in the LICENSE file.

import 'dart:async';

import 'package:app_finance/_classes/controller/fallback_localization_delegate.dart';
import 'package:app_finance/_classes/controller/encryption_handler.dart';
import 'package:app_finance/_classes/herald/app_design.dart';
import 'package:app_finance/_classes/herald/app_locale.dart';
import 'package:app_finance/_classes/herald/app_palette.dart';
import 'package:app_finance/_classes/herald/app_purchase.dart';
import 'package:app_finance/_classes/herald/app_start_of_month.dart';
import 'package:app_finance/_classes/herald/app_sync.dart';
import 'package:app_finance/_classes/herald/app_theme.dart';
import 'package:app_finance/_classes/herald/app_start_of_week.dart';
import 'package:app_finance/_classes/herald/app_zoom.dart';
import 'package:app_finance/_classes/math/budget_prediction.dart';
import 'package:app_finance/_classes/storage/app_preferences.dart';
import 'package:app_finance/_classes/storage/di/app_data_dependencies.dart';
import 'package:app_finance/_classes/structure/navigation/app_page_route.dart';
import 'package:app_finance/_configs/custom_color_scheme.dart';
import 'package:app_finance/_configs/custom_text_theme.dart';
import 'package:app_finance/_classes/storage/app_data.dart';
import 'package:app_finance/_classes/structure/navigation/app_route.dart';
import 'package:app_finance/_configs/firebase_options.dart';
import 'package:app_finance/l10n/app_localization.dart';
import 'package:app_finance/pages/about/about_page.dart';
import 'package:app_finance/pages/account/account_add_page.dart';
import 'package:app_finance/pages/account/account_edit_page.dart';
import 'package:app_finance/pages/account/account_view_page.dart';
import 'package:app_finance/pages/account/account_page.dart';
import 'package:app_finance/pages/automation/automation_page.dart';
import 'package:app_finance/pages/automation/payment_add_page.dart';
import 'package:app_finance/pages/automation/payment_edit_page.dart';
import 'package:app_finance/pages/automation/payment_view_page.dart';
import 'package:app_finance/pages/bill/bill_add_page.dart';
import 'package:app_finance/pages/bill/bill_edit_page.dart';
import 'package:app_finance/pages/bill/bill_page.dart';
import 'package:app_finance/pages/bill/bill_search_page.dart';
import 'package:app_finance/pages/bill/bill_view_page.dart';
import 'package:app_finance/pages/budget/budget_page.dart';
import 'package:app_finance/pages/budget/budget_add_page.dart';
import 'package:app_finance/pages/budget/budget_edit_page.dart';
import 'package:app_finance/pages/budget/budget_view_page.dart';
import 'package:app_finance/pages/currency/currency_add_page.dart';
import 'package:app_finance/pages/currency/currency_page.dart';
import 'package:app_finance/pages/goal/goal_add_page.dart';
import 'package:app_finance/pages/goal/goal_edit_page.dart';
import 'package:app_finance/pages/goal/goal_page.dart';
import 'package:app_finance/pages/goal/goal_view_page.dart';
import 'package:app_finance/pages/home/home_page.dart';
import 'package:app_finance/pages/invoice/invoice_edit_page.dart';
import 'package:app_finance/pages/invoice/invoice_page.dart';
import 'package:app_finance/pages/invoice/invoice_search_page.dart';
import 'package:app_finance/pages/invoice/invoice_transfer_page.dart';
import 'package:app_finance/pages/invoice/invoice_transfer_search_page.dart';
import 'package:app_finance/pages/invoice/invoice_view_page.dart';
import 'package:app_finance/pages/metrics/metrics_page.dart';
import 'package:app_finance/pages/settings/settings_page.dart';
import 'package:app_finance/pages/start/start_page.dart';
import 'package:app_finance/pages/subscription/subscription_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_currency_picker/flutter_currency_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final platform = DefaultFirebaseOptions.currentPlatform;
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (platform != null) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseAnalytics.instance.logAppOpen();
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseAnalytics.instance.logEvent(
          name: 'platform-error',
          parameters: {'error': error.toString(), 'trace': stack.toString()},
        );

        return true;
      };
      FlutterError.onError = kIsWeb
          ? (details) {
              FlutterError.presentError(details);
              FirebaseAnalytics.instance.logEvent(
                name: 'flutter-error',
                parameters: {'error': details.toString()},
              );
            }
          : FirebaseCrashlytics.instance.recordFlutterFatalError;
    }
    AppPreferences.pref = await SharedPreferences.getInstance();
    await EncryptionHandler.initialize();
    CurrencyDefaults.cache = AppPreferences.pref;
    final appSync = AppSync();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSync>(
            create: (_) => appSync,
          ),
          Provider<AppDataCollaboratorsFactory>(
            create: (_) => const DefaultAppDataCollaboratorsFactory(),
          ),
          Provider<AppDataTransactionLogGateway>(
            create: (_) => const TransactionLogGateway(),
          ),
          Provider<BudgetPrediction>(
            create: (_) => BudgetPrediction(),
          ),
          ProxyProvider3<BudgetPrediction, AppDataTransactionLogGateway, AppDataCollaboratorsFactory,
              AppDataDependencies>(
            update: (_, prediction, transactionLog, collaboratorsFactory, __) {
              return AppDataDependencies(
                prediction: prediction,
                transactionLog: transactionLog,
                collaboratorsFactory: collaboratorsFactory,
              );
            },
          ),
          ChangeNotifierProvider<AppData>(
            create: (context) => AppData(
              appSync,
              dependencies: context.read<AppDataDependencies>(),
            ),
          ),
          ChangeNotifierProvider<AppTheme>(
            create: (_) => AppTheme(ThemeMode.system),
          ),
          ChangeNotifierProvider<AppLocale>(
            create: (_) => AppLocale(),
          ),
          ChangeNotifierProvider<AppDesign>(
            create: (_) => AppDesign(),
          ),
          ChangeNotifierProvider<AppZoom>(
            create: (_) => AppZoom(),
          ),
          ChangeNotifierProvider<AppPalette>(
            create: (_) => AppPalette(),
          ),
          ChangeNotifierProvider<AppPurchase>(
            create: (_) => AppPurchase(),
          ),
          ChangeNotifierProvider<AppStartOfWeek>(
            create: (_) => AppStartOfWeek(),
          ),
          ChangeNotifierProvider<AppStartOfMonth>(
            create: (_) => AppStartOfMonth(),
          ),
        ],
        child: MyApp(platform: platform),
      ),
    );
  }, (error, stack) {
    if (platform != null) {
      if (kIsWeb) {
        FirebaseAnalytics.instance.logEvent(name: 'flutter-error', parameters: {'error': error.toString()});
      } else {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    }
    FlutterError.presentError(FlutterErrorDetails(exception: error, stack: stack));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.platform});

  final FirebaseOptions? platform;

  WidgetBuilder? _getPage(String route, Object? arguments) {
    AppRoute.current = route;
    final args = arguments as Map<String, dynamic>?;
    final String key = args?['uuid'] ?? args?['search'] ?? '';
    final int focus = args?['focus'] ?? 1;
    final screenParameters = args?.map<String, Object>((k, v) {
      return MapEntry(k, v ?? '');
    });
    if (platform != null) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: route,
        parameters: screenParameters,
      );
    }

    return (_) => Directionality(
          textDirection: TextDirection.ltr,
          child: switch (route) {
            AppRoute.aboutRoute => AboutPage(search: key),
            AppRoute.accountRoute => const AccountPage(),
            AppRoute.accountAddRoute => const AccountAddPage(),
            AppRoute.accountViewRoute => AccountViewPage(uuid: key),
            AppRoute.accountSearchRoute => AccountPage(search: key),
            AppRoute.accountEditRoute => AccountEditPage(uuid: key),
            AppRoute.automationRoute => const AutomationPage(),
            AppRoute.automationPaymentRoute => const PaymentAddPage(),
            AppRoute.automationPaymentViewRoute => PaymentViewPage(uuid: key),
            AppRoute.automationPaymentEditRoute => PaymentEditPage(uuid: key),
            AppRoute.billRoute => const BillPage(),
            AppRoute.billAddRoute => BillAddPage(focus: focus),
            AppRoute.billViewRoute => BillViewPage(uuid: key),
            AppRoute.billEditRoute => BillEditPage(uuid: key),
            AppRoute.billSearchRoute => BillSearchPage(),
            AppRoute.budgetRoute => const BudgetPage(),
            AppRoute.budgetAddRoute => const BudgetAddPage(),
            AppRoute.budgetViewRoute => BudgetViewPage(uuid: key),
            AppRoute.budgetSearchRoute => BudgetPage(search: key),
            AppRoute.budgetEditRoute => BudgetEditPage(uuid: key),
            AppRoute.currencyRoute => const CurrencyPage(),
            AppRoute.currencyAddRoute => const CurrencyAddPage(),
            AppRoute.goalRoute => const GoalPage(),
            AppRoute.goalAddRoute => const GoalAddPage(),
            AppRoute.goalViewRoute => GoalViewPage(uuid: key),
            AppRoute.goalEditRoute => GoalEditPage(uuid: key),
            AppRoute.invoiceRoute => InvoicePage(),
            AppRoute.invoiceViewRoute => InvoiceViewPage(uuid: key),
            AppRoute.invoiceEditRoute => InvoiceEditPage(uuid: key),
            AppRoute.invoiceSearchRoute => InvoiceSearchPage(),
            AppRoute.invoiceTransferRoute => InvoiceTransferPage(),
            AppRoute.invoiceTransferSearchRoute => InvoiceTransferSearchPage(),
            AppRoute.homeRoute => const HomePage(),
            AppRoute.metricsRoute => const MetricsPage(),
            AppRoute.metricsSearchRoute => MetricsPage(search: key),
            AppRoute.settingsRoute => const SettingsPage(),
            AppRoute.startRoute => const StartPage(),
            AppRoute.subscriptionRoute => const SubscriptionPage(),
            _ => const HomePage(),
          },
        );
  }

  Route<Widget>? _onGenerateRoute(RouteSettings settings) {
    final builder = _getPage(settings.name ?? '', settings.arguments);

    return AppPageRoute(
      builder: builder ?? (_) => const HomePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.watch<AppPalette>().value;
    final textTheme = theme.textTheme;
    final text = textTheme.withCustom(palette, Brightness.light);
    final textDark = textTheme.withCustom(palette, Brightness.dark);
    final sheet = theme.bottomSheetTheme.copyWith(
      constraints: const BoxConstraints(maxWidth: double.infinity),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        FallbackLocalizationDelegate(),
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: context.watch<AppLocale>().value,
      theme: ThemeData(
        colorScheme: const ColorScheme.light().withCustom(palette),
        floatingActionButtonTheme: const FloatingActionButtonThemeData().withCustom(palette, Brightness.light),
        brightness: Brightness.light,
        textTheme: text,
        datePickerTheme: DatePickerTheme.of(context).withCustom(palette, text, Brightness.light),
        timePickerTheme: TimePickerTheme.of(context).withCustom(palette, text, Brightness.light),
        dividerTheme: CustomDividerTheme(palette, Brightness.light),
        bottomSheetTheme: sheet,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark().withCustom(palette),
        floatingActionButtonTheme: const FloatingActionButtonThemeData().withCustom(palette, Brightness.dark),
        brightness: Brightness.dark,
        textTheme: textDark,
        datePickerTheme: DatePickerTheme.of(context).withCustom(palette, textDark, Brightness.dark),
        timePickerTheme: TimePickerTheme.of(context).withCustom(palette, textDark, Brightness.dark),
        dividerTheme: CustomDividerTheme(palette, Brightness.dark),
        bottomSheetTheme: sheet,
        useMaterial3: true,
      ),
      themeMode: context.watch<AppTheme>().value,
      home: const Directionality(
        textDirection: TextDirection.ltr,
        child: HomePage(),
      ),
      onGenerateRoute: _onGenerateRoute,
    );
  }
}
