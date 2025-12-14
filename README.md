# Amplitude Experiments Flutter

Flutter SDK for [Amplitude Experiment](https://amplitude.com/docs/experiment) - feature flags and A/B testing.

## Packages

This is a federated plugin with the following packages:

| Package | Description |
|---------|-------------|
| [amplitude_experiments_flutter](packages/amplitude_experiments_flutter/) | Main package (use this) |
| [amplitude_experiments_flutter_platform_interface](packages/amplitude_experiments_flutter_platform_interface/) | Platform interface |
| [amplitude_experiments_flutter_android](packages/amplitude_experiments_flutter_android/) | Android implementation |
| [amplitude_experiments_flutter_ios](packages/amplitude_experiments_flutter_ios/) | iOS implementation |

## Quick Start

```dart
import 'package:amplitude_experiments_flutter/amplitude_experiments_flutter.dart';

// Initialize
await AmplitudeExperiments.initialize('YOUR-DEPLOYMENT-KEY');

// Fetch variants for user
await AmplitudeExperiments.fetch(
  const ExperimentUser(userId: 'user-123'),
);

// Get variant
final variant = await AmplitudeExperiments.variant('my-flag');
if (variant?.isOn == true) {
  // Feature enabled
}
```

## Documentation

See the [main package README](packages/amplitude_experiments_flutter/README.md) for complete documentation.

## Development

This project uses [Melos](https://melos.invertase.dev/) for monorepo management.

```bash
# Install melos
dart pub global activate melos

# Bootstrap packages
melos bootstrap

# Run formatting
melos run format

# Run tests
melos run test
```

## License

MIT License
