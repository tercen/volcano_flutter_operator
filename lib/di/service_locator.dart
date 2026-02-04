import 'package:get_it/get_it.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart';
import '../domain/services/volcano_data_service.dart';
import '../implementations/services/mock_volcano_data_service.dart';
import '../implementations/services/tercen_volcano_data_service.dart';

final GetIt serviceLocator = GetIt.instance;

/// Initialize all services.
///
/// Parameters:
///   - [useMocks]: If true, registers mock implementations. If false, uses Tercen API.
///   - [tercenFactory]: Required when useMocks is false.
///   - [taskId]: Tercen task ID from URL query parameters.
void setupServiceLocator({
  bool useMocks = true,
  ServiceFactory? tercenFactory,
  String? taskId,
}) {
  if (useMocks) {
    // Register mock services for development/testing
    serviceLocator.registerLazySingleton<VolcanoDataService>(
      () => MockVolcanoDataService(),
    );
  } else {
    if (tercenFactory == null) {
      throw StateError(
        'Tercen ServiceFactory is required when useMocks is false. '
        'Call createServiceFactoryForWebApp() first.',
      );
    }

    // Register Tercen ServiceFactory
    serviceLocator.registerSingleton<ServiceFactory>(tercenFactory);

    // Register real volcano data service
    serviceLocator.registerLazySingleton<VolcanoDataService>(
      () => TercenVolcanoDataService(
        tercenFactory,
        taskId: taskId,
      ),
    );
  }
}

/// Resets the service locator (useful for testing).
Future<void> resetServiceLocator() async {
  await serviceLocator.reset();
}
