import 'package:zedu/core/core.dart';
import 'package:zedu/app/app.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await windowManager.ensureInitialized();
  }
  await loadAppEnv();
  setupLocator();

  runApp(const ProviderScope(child: App()));
}