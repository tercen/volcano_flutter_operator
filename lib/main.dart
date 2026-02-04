import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'di/service_locator.dart';
import 'presentation/providers/plot_settings_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/volcano_data_provider.dart';
import 'presentation/screens/volcano_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  setupServiceLocator();

  runApp(const VolcanoApp());
}

class VolcanoApp extends StatelessWidget {
  const VolcanoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlotSettingsProvider()),
        ChangeNotifierProvider(create: (_) => VolcanoDataProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Volcano Plot',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: const VolcanoScreen(),
          );
        },
      ),
    );
  }
}
