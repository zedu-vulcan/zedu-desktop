import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'Help',
          menus: [
            PlatformMenuItem(
              label: 'Export diagnostics',
              onSelected: () => DiagnosticsService.handleExportDiagnostics(null),
            ),
          ],
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Zedu',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
        builder: (context, child) => DesktopManager(
          child: CreditsPaymentDeepLinkListener(
            child: AuthDeepLinkListener(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
