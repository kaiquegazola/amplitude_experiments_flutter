import 'package:flutter/services.dart';

/// Utility class to detect DNS-related errors.
///
/// DNS issues are typically caused by ISP misconfiguration where the domain
/// resolves to invalid addresses like localhost (127.0.0.1) or any address (0.0.0.0).
class DnsErrorDetector {
  const DnsErrorDetector._();

  /// Checks if the error is related to DNS resolution issues.
  ///
  /// Returns `true` if the error indicates:
  /// - DNS failed to resolve (UnknownHostException)
  /// - DNS resolved to loopback addresses (127.0.0.1, localhost)
  /// - DNS resolved to any/invalid addresses (0.0.0.0, [::])
  static bool isDnsRelatedError(Object error) {
    final errorString = _getFullErrorString(error);

    // DNS failed to resolve entirely
    if (errorString.contains('UnknownHostException')) return true;

    // DNS resolved to invalid loopback/any addresses
    const invalidResolutions = [
      'localhost/',
      '/127.0.0.1',
      '/0.0.0.0',
      '/[::]:',
      '/[::]/',
    ];

    return invalidResolutions.any(errorString.contains);
  }

  static String _getFullErrorString(Object error) {
    if (error is PlatformException) {
      final message = error.message ?? '';
      final details = error.details?.toString() ?? '';
      return '$message $details';
    }
    return error.toString();
  }
}
