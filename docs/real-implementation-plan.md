# Volcano Flutter - Real Tercen Implementation Plan

## Overview

Convert the volcano_flutter application from mock CSV-based data to real Tercen API integration.

**Current State:** Mock service loads CSV from assets
**Target State:** Real service extracts data from Tercen CubeQueryTask projections

---

## Data Mapping

| Tercen Projection | GeneDataPoint Field | Description |
|-------------------|---------------------|-------------|
| `.x` | foldChange | X-axis value |
| `.y` | significance | Y-axis value (-log10 p-value) |
| row labels | name | Gene/kinase name |
| `.ci` | group | Column index for grouping |

---

## Implementation Steps

### Step 1: Add Tercen Dependency

**File:** `pubspec.yaml`

Add sci_tercen_client dependency:
```yaml
dependencies:
  # ... existing ...
  sci_tercen_client:
    git:
      url: https://github.com/tercen/sci_tercen_client.git
      ref: 1.7.0
      path: sci_tercen_client
```

Then run `flutter pub get`

---

### Step 2: Create Volcano Data Resolver

**New File:** `lib/utils/volcano_data_resolver.dart`

Creates a resolver class that:
- Takes ServiceFactory and taskId
- Gets CubeQueryTask from TaskService
- Extracts `.x`, `.y`, labels, and `.ci` from row schema
- Maps column indices to group names from column schema
- Returns `VolcanoData` with `GeneDataPoint` list

Key pattern (from ps12_image_overview_flutter_operator):
```dart
// Get task and handle RunWebAppTask vs CubeQueryTask
final task = await serviceFactory.taskService.get(taskId);
CubeQueryTask? cubeTask;
if (task is RunWebAppTask) {
  cubeTask = await serviceFactory.taskService.get(task.cubeQueryTaskId);
} else if (task is CubeQueryTask) {
  cubeTask = task;
}

// Extract data from row schema
final rowHash = cubeTask.query?.rowHash;
final rowData = await serviceFactory.tableSchemaService.select(rowHash, ['.x', '.y', '.ci', labelColumn], 0, 10000);
```

---

### Step 3: Create Real Tercen Service

**New File:** `lib/implementations/services/tercen_volcano_data_service.dart`

Implements `VolcanoDataService` interface:
- Uses `VolcanoDataResolver` to fetch data
- Falls back to `MockVolcanoDataService` on errors
- Caches loaded data

---

### Step 4: Update Service Locator

**File:** `lib/di/service_locator.dart`

Add environment-based service switching:
```dart
void setupServiceLocator({
  bool useMocks = true,
  ServiceFactory? tercenFactory,
  String? taskId,
}) {
  if (useMocks) {
    serviceLocator.registerLazySingleton<VolcanoDataService>(
      () => MockVolcanoDataService(),
    );
  } else {
    serviceLocator.registerSingleton<ServiceFactory>(tercenFactory);
    serviceLocator.registerLazySingleton<VolcanoDataService>(
      () => TercenVolcanoDataService(tercenFactory, taskId: taskId),
    );
  }
}
```

---

### Step 5: Update Main Entry Point

**File:** `lib/main.dart`

Follow pattern from ps12_image_overview:
- Add `USE_MOCKS` environment switch (default: false for production)
- Initialize Tercen with `createServiceFactoryForWebApp()`
- Parse URL for taskId
- Show error screen if taskId missing
- Call `setupServiceLocator()` with appropriate parameters

---

### Step 6: Update Deployment Files

**File:** `web/index.html`
- Comment out base href line: `<!--<base href="$FLUTTER_BASE_HREF">-->`

**File:** `.gitignore`
- Add exception: `!/build/web/`

**File:** `operator.json`
- Ensure `"isWebApp": true` and `"serve": "build/web"` are present

---

## Files Summary

| Action | File |
|--------|------|
| Modify | `pubspec.yaml` - add sci_tercen_client |
| Create | `lib/utils/volcano_data_resolver.dart` |
| Create | `lib/implementations/services/tercen_volcano_data_service.dart` |
| Modify | `lib/di/service_locator.dart` - add environment switching |
| Modify | `lib/main.dart` - add Tercen initialization |
| Modify | `web/index.html` - comment base href |
| Modify | `.gitignore` - add build/web exception |

---

## Verification

1. **Local Mock Testing:**
   ```bash
   flutter run -d chrome --dart-define=USE_MOCKS=true
   ```
   Verify app loads with mock CSV data

2. **Local Real Testing:**
   - Set dev token in localStorage (via index.html or browser console)
   - Run `flutter run -d chrome`
   - Test with valid Tercen URL containing taskId

3. **Production Deployment:**
   ```bash
   flutter build web --wasm
   git add build/web/
   git commit -m "Update web build for Tercen deployment"
   git push
   ```
   - Test in Tercen workflow with data step configured with x/y projections

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| No taskId in URL | Show user-friendly error screen |
| Tercen API error | Fall back to mock data with console warning |
| Missing projections | Fall back to mock data |
| Empty data | Fall back to mock data |
