import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Formato de fechas en español para el historial.
  await initializeDateFormatting('es');
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  final appState = AppState();
  await appState.init();

  runApp(FisuraScanApp(appState: appState));
}

class FisuraScanApp extends StatelessWidget {
  final AppState appState;
  const FisuraScanApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
