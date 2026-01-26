import 'package:amplitude_experiments_flutter_platform_interface/src/network/dns_error_detector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DnsErrorDetector', () {
    group('isDnsRelatedError', () {
      test('returns true for UnknownHostException', () {
        final error = PlatformException(
          code: 'FETCH_ERROR',
          message: 'java.net.UnknownHostException: api.lab.amplitude.com',
        );

        expect(DnsErrorDetector.isDnsRelatedError(error), isTrue);
      });

      test('returns true when hostname resolves to localhost', () {
        final error = PlatformException(
          code: 'FETCH_ERROR',
          message: 'Failed to connect to api.lab.amplitude.com',
          details: 'Caused by: failed to connect to localhost/127.0.0.1',
        );

        expect(DnsErrorDetector.isDnsRelatedError(error), isTrue);
      });

      test('returns true when hostname resolves to 127.0.0.1', () {
        final error = PlatformException(
          code: 'FETCH_ERROR',
          message:
              'ConnectException: Failed to connect to api.lab.amplitude.com/127.0.0.1:443',
        );

        expect(DnsErrorDetector.isDnsRelatedError(error), isTrue);
      });

      test('returns true when hostname resolves to 0.0.0.0', () {
        final error = PlatformException(
          code: 'FETCH_ERROR',
          message: 'Failed to connect to api.lab.amplitude.com/0.0.0.0:443',
        );

        expect(DnsErrorDetector.isDnsRelatedError(error), isTrue);
      });

      test('returns true when hostname resolves to IPv6 any address [::]', () {
        final error = PlatformException(
          code: 'FETCH_ERROR',
          message: 'Failed to connect to api.lab.amplitude.com/[::]:443',
        );

        expect(DnsErrorDetector.isDnsRelatedError(error), isTrue);
      });

      test('returns true for complex stack trace with DNS issue', () {
        final error = PlatformException(
          code: 'FETCH_ERROR',
          message: 'java.util.concurrent.ExecutionException',
          details: '''
java.net.ConnectException: Failed to connect to api.lab.amplitude.com/[::]:443
    at okhttp3.internal.connection.RealConnection.connectSocket(RealConnection.kt:297)
Caused by: java.net.ConnectException: failed to connect to localhost/127.0.0.1 (port 443)
    at libcore.io.IoBridge.isConnected(IoBridge.java:347)
Caused by: android.system.ErrnoException: isConnected failed: ECONNREFUSED
          ''',
        );

        expect(DnsErrorDetector.isDnsRelatedError(error), isTrue);
      });

      test('returns false for regular network timeout', () {
        final error = PlatformException(
          code: 'FETCH_ERROR',
          message: 'SocketTimeoutException: connect timed out',
        );

        expect(DnsErrorDetector.isDnsRelatedError(error), isFalse);
      });

      test('returns false for HTTP 401 error', () {
        final error = PlatformException(
          code: 'FETCH_ERROR',
          message: 'HTTP 401 Unauthorized',
        );

        expect(DnsErrorDetector.isDnsRelatedError(error), isFalse);
      });

      test('returns false for SSL certificate error', () {
        final error = PlatformException(
          code: 'FETCH_ERROR',
          message: 'SSLHandshakeException: Certificate validation failed',
        );

        expect(DnsErrorDetector.isDnsRelatedError(error), isFalse);
      });

      test('returns false for non-PlatformException errors', () {
        final error = Exception('Some other error');

        expect(DnsErrorDetector.isDnsRelatedError(error), isFalse);
      });

      test('returns false for generic connection refused without localhost',
          () {
        final error = PlatformException(
          code: 'FETCH_ERROR',
          message: 'Connection refused to 192.168.1.1:443',
        );

        expect(DnsErrorDetector.isDnsRelatedError(error), isFalse);
      });
    });
  });
}
