import 'package:get_it/get_it.dart';
import '../domain/services/volcano_data_service.dart';
import '../implementations/services/mock_volcano_data_service.dart';

final GetIt serviceLocator = GetIt.instance;

/// Initialize all services
void setupServiceLocator() {
  // Register data service (mock implementation)
  serviceLocator.registerLazySingleton<VolcanoDataService>(
    () => MockVolcanoDataService(),
  );
}
