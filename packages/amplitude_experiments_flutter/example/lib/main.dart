import 'package:amplitude_experiments_flutter/amplitude_experiments_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  String _statusMessage = 'Not initialized';
  String _variantValue = 'Not fetched';
  Map<String, Variant> _allVariants = {};

  @override
  void initState() {
    super.initState();
    _initializeExperiments();
  }

  Future<void> _initializeExperiments() async {
    try {
      setState(() {
        _statusMessage = 'Initializing...';
      });

      // Replace with your actual deployment key
      const deploymentKey = 'client-YOUR-DEPLOYMENT-KEY';

      await AmplitudeExperiments.initialize(
        deploymentKey,
        config: const ExperimentConfig(
          debug: true,
          fetchOnStart: false,
          automaticExposureTracking: true,
          initialVariants: {
            'test-flag': Variant(key: 'test-flag', value: 'on'),
          },
        ),
      );

      final variants = await AmplitudeExperiments.all();

      setState(() {
        _isInitialized = true;
        _statusMessage = 'Initialized successfully';
        _allVariants = variants;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _fetchVariants() async {
    try {
      setState(() {
        _statusMessage = 'Fetching variants...';
      });

      await AmplitudeExperiments.fetch(
        const ExperimentUser(
          userId: 'test-user-123',
          deviceId: 'test-device-456',
          userProperties: {'plan': 'premium', 'age': 25},
        ),
      );

      final variants = await AmplitudeExperiments.all();

      setState(() {
        _allVariants = variants;
        _statusMessage = 'Fetched ${variants.length} variants';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Fetch error: $e';
      });
    }
  }

  Future<void> _getVariant() async {
    try {
      final variant = await AmplitudeExperiments.variant(
        'test-flag',
        const Variant(key: 'test-flag', value: 'control'),
      );

      setState(() {
        _variantValue = variant?.value ?? 'null';
        _statusMessage = 'Got variant: $_variantValue';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Variant error: $e';
      });
    }
  }

  Future<void> _trackExposure() async {
    try {
      await AmplitudeExperiments.exposure('test-flag');
      setState(() {
        _statusMessage = 'Exposure tracked for test-flag';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Exposure error: $e';
      });
    }
  }

  Future<void> _clearCache() async {
    try {
      await AmplitudeExperiments.clear();
      final variants = await AmplitudeExperiments.all();
      setState(() {
        _allVariants = variants;
        _variantValue = 'cleared';
        _statusMessage = 'Cache cleared';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Clear error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Amplitude Experiments'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_statusMessage),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _isInitialized ? Icons.check_circle : Icons.cancel,
                            color: _isInitialized ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isInitialized ? 'Initialized' : 'Not Initialized',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Current variant: $_variantValue'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isInitialized ? _fetchVariants : null,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Fetch'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isInitialized ? _getVariant : null,
                    icon: const Icon(Icons.search),
                    label: const Text('Get Variant'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isInitialized ? _trackExposure : null,
                    icon: const Icon(Icons.visibility),
                    label: const Text('Track Exposure'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isInitialized ? _clearCache : null,
                    icon: const Icon(Icons.delete),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Variants List
              Text(
                'All Variants (${_allVariants.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _allVariants.isEmpty
                    ? const Center(child: Text('No variants loaded'))
                    : ListView.builder(
                        itemCount: _allVariants.length,
                        itemBuilder: (context, index) {
                          final entry = _allVariants.entries.elementAt(index);
                          final variant = entry.value;
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                variant.isOn
                                    ? Icons.toggle_on
                                    : Icons.toggle_off,
                                color: variant.isOn
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              title: Text(entry.key),
                              subtitle: Text(
                                'Value: ${variant.value ?? "null"}',
                              ),
                              trailing: variant.payload != null
                                  ? const Tooltip(
                                      message: 'Has payload',
                                      child: Icon(Icons.data_object),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
