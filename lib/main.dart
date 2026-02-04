import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sci_tercen_client/sci_service_factory_web.dart';
import 'core/theme/app_theme.dart';
import 'di/service_locator.dart';
import 'presentation/providers/plot_settings_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/volcano_data_provider.dart';
import 'presentation/screens/volcano_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if we should use mock services or real Tercen API
  // Default to false (real data) when deployed to Tercen
  // Override with --dart-define=USE_MOCKS=true for local development with mocks
  const useMocks = bool.fromEnvironment(
    'USE_MOCKS',
    defaultValue: false, // Default to real Tercen API (production mode)
  );

  if (useMocks) {
    // Use mock services for development/testing
    setupServiceLocator(useMocks: true);
  } else {
    // Initialize Tercen ServiceFactory with token and URI from environment
    final tercenFactory = await createServiceFactoryForWebApp();

    // Parse URL to extract Tercen parameters
    final uri = Uri.base;
    final pathSegments = uri.pathSegments;
    final queryParams = uri.queryParameters;

    print('URL Analysis:');
    print('   Full URL: $uri');
    print('   Path segments: $pathSegments');
    print('   Query parameters: ${queryParams.keys.join(", ")}');

    // Extract parameters from query string (primary source for operators)
    String? taskId = queryParams['taskId'];
    String? workflowId = queryParams['workflowId'];
    String? stepId = queryParams['stepId'];

    print('Query parameters:');
    print('   taskId: $taskId');
    print('   workflowId: $workflowId');
    print('   stepId: $stepId');

    // Also check path segments for workflow mode (legacy support)
    if (pathSegments.contains('w') && pathSegments.contains('ds')) {
      final wIndex = pathSegments.indexOf('w');
      final dsIndex = pathSegments.indexOf('ds');
      if (wIndex + 1 < pathSegments.length && dsIndex + 1 < pathSegments.length) {
        workflowId ??= pathSegments[wIndex + 1];
        stepId ??= pathSegments[dsIndex + 1];
        print('Also found in path: workflowId=$workflowId, stepId=$stepId');
      }
    }

    print('Final configuration:');
    print('   taskId: $taskId');
    print('   workflowId: $workflowId');
    print('   stepId: $stepId');

    // Validate required parameters for production mode
    if (taskId == null || taskId.isEmpty) {
      print('Error: Missing required parameter "taskId"');
      runApp(_buildErrorApp(
        'Missing Required Parameter',
        'This operator requires a "taskId" parameter.\n\n'
        'Please launch this operator from a Tercen workflow step.',
      ));
      return;
    }

    // Set up service locator with real Tercen services
    setupServiceLocator(
      useMocks: false,
      tercenFactory: tercenFactory,
      taskId: taskId,
    );
  }

  runApp(const VolcanoApp());
}

/// Builds an error screen with a user-friendly message.
Widget _buildErrorApp(String title, String message) {
  return MaterialApp(
    title: 'Volcano Plot - Error',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.red,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    ),
    home: Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
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
