# amplitude_experiments_flutter_platform_interface

A common platform interface for the [`amplitude_experiments_flutter`](https://pub.dev/packages/amplitude_experiments_flutter) plugin.

This interface allows platform-specific implementations of the `amplitude_experiments_flutter` plugin, as well as the plugin itself, to ensure they are supporting the same interface.

## Usage

To implement a new platform-specific implementation of `amplitude_experiments_flutter`, extend `AmplitudeExperimentsFlutterPlatform` with an implementation that performs the platform-specific behavior.
