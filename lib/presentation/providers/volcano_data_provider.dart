import 'package:flutter/foundation.dart';
import '../../di/service_locator.dart';
import '../../domain/models/volcano_data.dart';
import '../../domain/services/volcano_data_service.dart';

/// Provider for managing volcano plot data state
class VolcanoDataProvider extends ChangeNotifier {
  final VolcanoDataService _dataService;

  VolcanoData _data = VolcanoData.empty();
  bool _isLoading = false;
  String? _error;

  VolcanoDataProvider({VolcanoDataService? dataService})
      : _dataService = dataService ?? serviceLocator<VolcanoDataService>();

  VolcanoData get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _data.points.isNotEmpty;

  /// Load data from the service
  Future<void> loadData() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _dataService.loadData();
      _error = null;
    } catch (e) {
      _error = 'Failed to load data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh data from the service
  Future<void> refreshData() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _dataService.refreshData();
      _error = null;
    } catch (e) {
      _error = 'Failed to refresh data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a different comparison group
  void selectGroup(String group) {
    if (_data.groups.contains(group) && _data.selectedGroup != group) {
      _data = _data.selectGroup(group);
      notifyListeners();
    }
  }
}
