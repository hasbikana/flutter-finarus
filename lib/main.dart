import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/colors.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/saving_goal_provider.dart';
import 'providers/account_provider.dart';
import 'providers/report_provider.dart';
import 'providers/settings_provider.dart';
import 'services/api_service.dart';
import 'services/dashboard_service.dart';
import 'services/transaction_service.dart';
import 'services/category_service.dart';
import 'services/budget_service.dart';
import 'services/saving_goal_service.dart';
import 'services/account_service.dart';
import 'services/report_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'services/pending_notification_service.dart';
import 'providers/notification_provider.dart';
import 'providers/ocr_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(DashboardService(() => null)),
          update: (_, auth, prev) => DashboardProvider(
            DashboardService(() => auth.token),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (_) => TransactionProvider(TransactionService(() => null)),
          update: (_, auth, prev) => TransactionProvider(
            TransactionService(() => auth.token),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
          create: (_) => CategoryProvider(CategoryService(() => null)),
          update: (_, auth, prev) => CategoryProvider(
            CategoryService(() => auth.token),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BudgetProvider>(
          create: (_) => BudgetProvider(BudgetService(() => null)),
          update: (_, auth, prev) => BudgetProvider(
            BudgetService(() => auth.token),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SavingGoalProvider>(
          create: (_) => SavingGoalProvider(SavingGoalService(() => null)),
          update: (_, auth, prev) => SavingGoalProvider(
            SavingGoalService(() => auth.token),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AccountProvider>(
          create: (_) => AccountProvider(AccountService(() => null)),
          update: (_, auth, prev) => AccountProvider(
            AccountService(() => auth.token),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReportProvider>(
          create: (_) => ReportProvider(ReportService(() => null)),
          update: (_, auth, prev) => ReportProvider(
            ReportService(() => auth.token),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SettingsProvider>(
          create: (_) => SettingsProvider(SettingsService(ApiService())),
          update: (_, auth, prev) {
            final api = ApiService();
            if (auth.token != null) api.setToken(auth.token);
            return SettingsProvider(SettingsService(api));
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, prev) => NotificationProvider(
            pendingService: auth.token != null
                ? PendingNotificationService(() => auth.token)
                : null,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OcrProvider>(
          create: (_) => OcrProvider(() => null),
          update: (_, auth, prev) => OcrProvider(() => auth.token),
        ),
      ],
      child: MaterialApp(
        title: 'Finarus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: FinarusColors.primary,
          scaffoldBackgroundColor: FinarusColors.background,
          cardColor: FinarusColors.card,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('lib/assets/logo/LogoAPP.png', width: 120),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const MainShell();
    }

    return const LoginScreen();
  }
}
