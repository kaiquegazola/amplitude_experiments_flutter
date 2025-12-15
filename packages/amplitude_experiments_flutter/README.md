# Amplitude Experiments Flutter

Flutter SDK for [Amplitude Experiment](https://amplitude.com/docs/experiment), providing feature flags and A/B testing capabilities.

## Features

- Initialize Amplitude Experiments client
- Fetch feature flag variants for users
- Access variants with fallback values
- Manual exposure tracking
- Integration with Amplitude Analytics

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  amplitude_experiments_flutter: ^0.0.1
```

Then run:

```bash
flutter pub get
```

### Platform Requirements

| Platform | Minimum Version |
|----------|-----------------|
| iOS      | 13.0            |
| Android  | API 24          |

## Usage

### Initialize

```dart
import 'package:amplitude_experiments_flutter/amplitude_experiments_flutter.dart';

// Basic initialization
await AmplitudeExperiments.initialize('YOUR-DEPLOYMENT-KEY');

// With configuration
await AmplitudeExperiments.initialize(
  'YOUR-DEPLOYMENT-KEY',
  config: const ExperimentConfig(
    debug: true,
    fetchOnStart: true,
    automaticExposureTracking: true,
  ),
);
```

### Fetch Variants

```dart
// Fetch for a specific user
await AmplitudeExperiments.fetch(
  const ExperimentUser(
    userId: 'user-123',
    deviceId: 'device-456',
    userProperties: {'plan': 'premium'},
  ),
);

// Fetch for anonymous user
await AmplitudeExperiments.fetch();
```

### Get Variant

```dart
// Get a variant with fallback
final variant = await AmplitudeExperiments.variant(
  'my-feature-flag',
  const Variant(key: 'control', value: 'off'),
);

// Check variant value
if (variant?.value == 'on') {
  // Show new feature
}

// Check if variant is "on"
if (variant?.isOn == true) {
  // Feature is enabled
}
```

### Get All Variants

```dart
final variants = await AmplitudeExperiments.all();

for (final entry in variants.entries) {
  print('${entry.key}: ${entry.value.value}');
}
```

### Track Exposure

```dart
// Manual exposure tracking (when automaticExposureTracking is false)
await AmplitudeExperiments.exposure('my-feature-flag');
```

### Clear Cache

```dart
// Clear all cached variants (useful on logout)
await AmplitudeExperiments.clear();
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `debug` | `bool` | `false` | Enable debug logging |
| `instanceName` | `String?` | `null` | Instance name for multiple clients |
| `serverZone` | `ServerZone` | `us` | Server zone (`us` or `eu`) |
| `fetchTimeoutMillis` | `int` | `10000` | Fetch request timeout in ms |
| `retryFetchOnFailure` | `bool` | `true` | Retry failed fetch requests |
| `automaticExposureTracking` | `bool` | `true` | Auto-track exposures on variant access |
| `fetchOnStart` | `bool` | `false` | Fetch variants on initialization |
| `initialVariants` | `Map<String, Variant>?` | `null` | Pre-populate variants |

## Models

### ExperimentUser

```dart
const user = ExperimentUser(
  userId: 'user-123',
  deviceId: 'device-456',
  userProperties: {'plan': 'premium', 'age': 25},
  groups: {'company': ['Acme Inc']},
);
```

### Variant

```dart
final variant = Variant(
  key: 'treatment',
  value: 'on',
  payload: {'color': 'blue'},
);

// Properties
variant.key;      // Variant key
variant.value;    // Variant value
variant.payload;  // Optional JSON payload
variant.isOn;     // true if value is "on"
variant.isOff;    // true if value is null, empty, or "off"
```

## Example

See the [example](example/) directory for a complete sample app.

## License

MIT License - see [LICENSE](../../LICENSE) for details.
